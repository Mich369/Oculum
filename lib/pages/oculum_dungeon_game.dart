import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'oculum_dungeon/monster_book.dart';

part 'oculum_dungeon/oculum_dungeon_models.dart';
part 'oculum_dungeon/oculum_dungeon_sprite_painter.dart';
part 'oculum_dungeon/oculum_dungeon_skin_system.dart';

class OculumDungeonGameDialog extends StatefulWidget {
  const OculumDungeonGameDialog({
    super.key,
    required this.linguaInglese,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.playerName,
    required this.playerMaxHp,
    required this.playerVc,
    required this.playerCm,
    required this.playerDefense,
    required this.playerDamage,
    required this.playerInitiative,
    required this.playerLevel,
    required this.playerGrade,
    required this.onReward,
    this.onThemeUnlocked,
    this.initialUnlockedThemePresetIds = const [],
  });

  final bool linguaInglese;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  final String playerName;
  final int playerMaxHp;
  final int playerVc;
  final int playerCm;
  final int playerDefense;
  final int playerDamage;
  final int playerInitiative;
  final int playerLevel;
  final int playerGrade;

  final void Function({int obser, int ascensionDust, String? log}) onReward;
  final void Function(String presetId)? onThemeUnlocked;
  final List<String> initialUnlockedThemePresetIds;

  @override
  State<OculumDungeonGameDialog> createState() =>
      _OculumDungeonGameDialogState();
}

class _DungeonThemeUnlockDef {
  const _DungeonThemeUnlockDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.color,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final Color color;
}

class _OculumDungeonGameDialogState extends State<OculumDungeonGameDialog> {
  final ScrollController _skinCodexScrollController = ScrollController();
  final Random _random = Random();
  late String playerNameInRun;

  int rasterCacheDimension(
    double logicalPixels, {
    int min = 24,
    int max = 2048,
  }) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    return (logicalPixels * dpr).clamp(min.toDouble(), max.toDouble()).round();
  }

  void refreshDungeonUi([VoidCallback? action]) {
    if (!mounted) return;
    setState(action ?? () {});
  }

  bool readSavedBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'si') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  int readSavedInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim()) ??
          double.tryParse(value.trim().replaceAll(',', '.'))?.toInt() ??
          fallback;
    }
    return fallback;
  }

  List<String> readSavedStringList(dynamic value) {
    if (value is! List) return <String>[];
    return value.map((item) => item.toString()).toList();
  }

  List<int> readSavedIntList(dynamic value) {
    if (value is! List) return <int>[];
    return value.map((item) => readSavedInt(item)).toList();
  }

  Map<String, int> readSavedIntMap(dynamic value) {
    if (value is! Map) return <String, int>{};
    return value.map(
      (key, item) => MapEntry(key.toString(), readSavedInt(item)),
    );
  }

  Future<void> promptPlayerNameInput() async {
    final controller = TextEditingController(text: playerNameInRun);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0C16),
        title: Text(
          t('Inserisci nome', 'Enter name'),
          style: const TextStyle(color: Color(0xFFF4F0FF)),
        ),
        content: TextField(
          controller: controller,
          maxLength: 24,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFF4F0FF)),
          decoration: InputDecoration(
            hintText: t('Nome personaggio', 'Character name'),
            hintStyle: const TextStyle(color: Color(0xFF9F97BC)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t('Conferma', 'Confirm')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null) return;
    if (!mounted) return;
    final safe = newName.isEmpty ? '???' : newName;
    setState(() {
      playerNameInRun = safe;
    });
    addLog(t('Nome aggiornato: $safe', 'Name updated: $safe'));
  }

  static const List<_ElementDef> _elements = [
    _ElementDef(
      id: 'neutral',
      nameIt: 'Neutro',
      nameEn: 'Neutral',
      color: Color(0xFFBFB7DD),
      verbIt: 'taglia',
      verbEn: 'cuts',
    ),
    _ElementDef(
      id: 'fire',
      nameIt: 'Fuoco',
      nameEn: 'Fire',
      color: Color(0xFFFF5A3C),
      verbIt: 'brucia',
      verbEn: 'burns',
    ),
    _ElementDef(
      id: 'wind',
      nameIt: 'Vento',
      nameEn: 'Wind',
      color: Color(0xFF7EE7C8),
      verbIt: 'squarcia',
      verbEn: 'rends',
    ),
    _ElementDef(
      id: 'water',
      nameIt: 'Acqua',
      nameEn: 'Water',
      color: Color(0xFF44A7FF),
      verbIt: 'sommerge',
      verbEn: 'drowns',
    ),
    _ElementDef(
      id: 'earth',
      nameIt: 'Terra',
      nameEn: 'Earth',
      color: Color(0xFFC49A5A),
      verbIt: 'schiaccia',
      verbEn: 'crushes',
    ),
    _ElementDef(
      id: 'ice',
      nameIt: 'Ghiaccio',
      nameEn: 'Ice',
      color: Color(0xFF9BE7FF),
      verbIt: 'congela',
      verbEn: 'freezes',
    ),
    _ElementDef(
      id: 'sound',
      nameIt: 'Suono',
      nameEn: 'Sound',
      color: Color(0xFFFF8DD8),
      verbIt: 'frantuma',
      verbEn: 'shatters',
    ),
    _ElementDef(
      id: 'psyche',
      nameIt: 'Psico',
      nameEn: 'Psyche',
      color: Color(0xFFFF7CE5),
      verbIt: 'contorce',
      verbEn: 'warps',
    ),
    _ElementDef(
      id: 'lava',
      nameIt: 'Lava',
      nameEn: 'Lava',
      color: Color(0xFFFF7A1A),
      verbIt: 'fonde',
      verbEn: 'melts',
    ),
    _ElementDef(
      id: 'lightning',
      nameIt: 'Fulmine',
      nameEn: 'Lightning',
      color: Color(0xFFFFF06A),
      verbIt: 'folgora',
      verbEn: 'shocks',
    ),
    _ElementDef(
      id: 'poison',
      nameIt: 'Veleno',
      nameEn: 'Poison',
      color: Color(0xFF78D64B),
      verbIt: 'corrode',
      verbEn: 'corrodes',
    ),
    _ElementDef(
      id: 'ash',
      nameIt: 'Cenere',
      nameEn: 'Ash',
      color: Color(0xFF8D8A82),
      verbIt: 'soffoca',
      verbEn: 'chokes',
    ),
    _ElementDef(
      id: 'blood',
      nameIt: 'Sangue',
      nameEn: 'Blood',
      color: Color(0xFFC5283D),
      verbIt: 'dissangua',
      verbEn: 'bleeds',
    ),
    _ElementDef(
      id: 'crystal',
      nameIt: 'Cristallo',
      nameEn: 'Crystal',
      color: Color(0xFFA98BFF),
      verbIt: 'rifrange',
      verbEn: 'refracts',
    ),
    _ElementDef(
      id: 'shadow',
      nameIt: 'Ombra',
      nameEn: 'Shadow',
      color: Color(0xFF4C3A78),
      verbIt: 'inghiotte',
      verbEn: 'devours',
    ),
    _ElementDef(
      id: 'moon',
      nameIt: 'Luna',
      nameEn: 'Moon',
      color: Color(0xFFD7B9FF),
      verbIt: 'ricorda',
      verbEn: 'remembers',
    ),
    _ElementDef(
      id: 'sun',
      nameIt: 'Sole',
      nameEn: 'Sun',
      color: Color(0xFFFFD36A),
      verbIt: 'giudica',
      verbEn: 'judges',
    ),
    _ElementDef(
      id: 'vapium',
      nameIt: 'Vapium',
      nameEn: 'Vapium',
      color: Color(0xFFA7AAB8),
      verbIt: 'condensa',
      verbEn: 'condenses',
    ),
    _ElementDef(
      id: 'bone',
      nameIt: 'Osso',
      nameEn: 'Bone',
      color: Color(0xFFE8DEC7),
      verbIt: 'scricchiola',
      verbEn: 'cracks',
    ),
    _ElementDef(
      id: 'gravity',
      nameIt: 'Gravità',
      nameEn: 'Gravity',
      color: Color(0xFF7C5CFF),
      verbIt: 'schiaccia il cielo su',
      verbEn: 'pulls the sky onto',
    ),
    _ElementDef(
      id: 'nullum',
      nameIt: 'Null',
      nameEn: 'Null',
      color: Color(0xFF1F2230),
      verbIt: 'cancella',
      verbEn: 'erases',
    ),
    _ElementDef(
      id: 'dream',
      nameIt: 'Sogno',
      nameEn: 'Dream',
      color: Color(0xFFB6A0FF),
      verbIt: 'addormenta',
      verbEn: 'lulls',
    ),
    _ElementDef(
      id: 'metal',
      nameIt: 'Metallo',
      nameEn: 'Metal',
      color: Color(0xFF9AA1AE),
      verbIt: 'lacera',
      verbEn: 'rips',
    ),
    _ElementDef(
      id: 'postea',
      nameIt: 'Postea',
      nameEn: 'Postea',
      color: Color(0xFF8FB7FF),
      verbIt: 'anticipa',
      verbEn: 'preempts',
    ),
    _ElementDef(
      id: 'flora',
      nameIt: 'Radice',
      nameEn: 'Root',
      color: Color(0xFF55B86B),
      verbIt: 'avvolge',
      verbEn: 'binds',
    ),
    _ElementDef(
      id: 'slime',
      nameIt: 'Slime',
      nameEn: 'Slime',
      color: Color(0xFF63D8FF),
      verbIt: 'rimbalza su',
      verbEn: 'bounces onto',
    ),
    _ElementDef(
      id: 'oculum',
      nameIt: 'Oculum',
      nameEn: 'Oculum',
      color: Color(0xFF8B5CF6),
      verbIt: 'scruta',
      verbEn: 'scries',
    ),
  ];
  static const List<_CharacterOrigin> _characterOrigins = [
    _CharacterOrigin(
      id: 'male_dim_oculum',
      nameIt: 'Maschio',
      nameEn: 'Male',
      descIt:
          'Taglio corto, postura da lama e scudo. +1 danno, +8 Scudo. Può incontrare una controparte femminile per allenamenti speciali.',
      descEn:
          'Short cut, blade-and-shield stance. +1 damage, +8 Shield. Can meet a feminine counterpart for special training.',
      spriteKind: 'human_oculian_male',
      primaryColor: Color(0xFFC49A5A),
      hpBonus: 0,
      shieldBonus: 8,
      damageBonus: 1,
      defenseBonus: 0,
      oculumBonus: 0,
      partnerNameIt: 'Ragazza dall Oculum Spento',
      partnerNameEn: 'Dim-Oculum Girl',
    ),
    _CharacterOrigin(
      id: 'female_dim_oculum',
      nameIt: 'Femmina',
      nameEn: 'Female',
      descIt:
          'Capelli medi/lunghi, lettura prudente del dungeon. +10 HP, +1 difesa. Può incontrare una controparte maschile per allenamenti speciali.',
      descEn:
          'Medium/long hair, careful dungeon reading. +10 HP, +1 defense. Can meet a masculine counterpart for special training.',
      spriteKind: 'human_fem_hair',
      primaryColor: Color(0xFFD7B9FF),
      hpBonus: 10,
      shieldBonus: 0,
      damageBonus: 0,
      defenseBonus: 1,
      oculumBonus: 0,
      partnerNameIt: 'Ragazzo dall Oculum Spento',
      partnerNameEn: 'Dim-Oculum Boy',
    ),
    _CharacterOrigin(
      id: 'neutral_relic_witness',
      nameIt: 'Occhio della Reliquia',
      nameEn: 'Relic Eye',
      descIt:
          'Occhio reliquiario risvegliato. +1 Oculum run, +4 Scudo. Apre eventi di reliquia più spesso.',
      descEn:
          'Awakened relic eye. +1 run Oculum, +4 Shield. Opens relic events more often.',
      spriteKind: 'relic_eye',
      primaryColor: Color(0xFF8B5CF6),
      hpBonus: 0,
      shieldBonus: 4,
      damageBonus: 0,
      defenseBonus: 0,
      oculumBonus: 1,
      partnerNameIt: 'Testimone Senza Nome',
      partnerNameEn: 'Nameless Witness',
    ),
    _CharacterOrigin(
      id: 'pawn_awakened',
      nameIt: 'Pedina Risvegliata',
      nameEn: 'Awakened Pawn',
      descIt:
          'Una pedina che ha imparato a muoversi fuori dalla scacchiera. +12 Scudo, +1 difesa, +1 Oculum run.',
      descEn:
          'A pawn that learned to move beyond the board. +12 Shield, +1 defense, +1 run Oculum.',
      spriteKind: 'pawn',
      primaryColor: Color(0xFF9B7CFF),
      hpBonus: 0,
      shieldBonus: 12,
      damageBonus: 0,
      defenseBonus: 1,
      oculumBonus: 1,
      partnerNameIt: 'Pedina Gemella',
      partnerNameEn: 'Twin Pawn',
    ),
    _CharacterOrigin(
      id: 'male_oculian_cultist',
      nameIt: 'Cultista dell\'Occhio Viola (Maschio)',
      nameEn: 'Cultist of the Purple Eye (Male)',
      descIt:
          'Versione maschile del Cultista. Gli Oculiani non ti cacciano più: iniziano a leggerti come alleato.',
      descEn:
          'Male Cultist variant. Oculians no longer hunt you: they start reading you as an ally.',
      spriteKind: 'human_masc_hair',
      primaryColor: Color(0xFF8B5CF6),
      hpBonus: 0,
      shieldBonus: 8,
      damageBonus: 1,
      defenseBonus: 1,
      oculumBonus: 1,
      partnerNameIt: 'Cultista Viola',
      partnerNameEn: 'Purple Cultist',
    ),
    _CharacterOrigin(
      id: 'female_oculian_cultist',
      nameIt: 'Cultista dell\'Occhio Viola (Femmina)',
      nameEn: 'Cultist of the Purple Eye (Female)',
      descIt:
          'Versione femminile del Cultista. Ottieni il patto Oculiano: meno ostilità, più supporto mistico.',
      descEn:
          'Female Cultist variant. You gain the Oculian pact: less hostility, more mystical support.',
      spriteKind: 'human_oculian_female',
      primaryColor: Color(0xFFB6A0FF),
      hpBonus: 6,
      shieldBonus: 6,
      damageBonus: 0,
      defenseBonus: 1,
      oculumBonus: 1,
      partnerNameIt: 'Cultista Viola',
      partnerNameEn: 'Purple Cultist',
    ),
  ];
  late final List<_DungeonArt> _allArts = _generateArts();
  late final List<_EnemyTemplate> _enemies = _generateEnemies();
  late final List<_ShopItem> _shopItems = _generateShopItems();
  late final List<_UniqueDrop> _uniqueDrops = _generateDrops();
  late final List<_GoodNpc> _goodNpcs = _generateGoodNpcs();
  late final List<_AchievementDef> _achievements = _generateAchievements();
  late final List<_RelicDef> _allRelics = _generateRelics();
  late final List<_TitleDef> _allTitles = _generateTitles();

  bool runActive = false;
  bool inCombat = false;
  bool gameOver = false;
  bool victory = false;
  bool enemyTurnPending = false;

  bool get canUseCombatInput => inCombat && !gameOver && !enemyTurnPending;

  int runCount = 0;
  int room = 0;
  int maxRooms = 72;
  int threat = 1;
  int runGrade = 1;
  int cycleDay = 1;
  int dungeonFloor = 1;

  int playerHp = 30;
  int playerMaxHp = 30;
  int playerShield = 0;
  int playerOculumShield = 0;
  int playerOculumShieldMax = 0;
  int dungeonKarma = 0;

  int dungeonLevel = 0;
  int dungeonExp = 0;
  int dungeonResilienza = 0;
  int dungeonVolonta = 0;
  int dungeonMateria = 0;
  int dungeonOculum = 0;
  int spentRunResilienza = 0;
  int spentRunVolonta = 0;
  int spentRunMateria = 0;
  int spentRunOculum = 0;

  int enemyHp = 0;
  int enemyMaxHp = 0;
  int enemyAttack = 0;
  int enemyDefense = 0;
  int enemyBleed = 0;
  int enemyBurn = 0;
  int enemyWeak = 0;
  int playerStunTurns = 0;
  int playerSlowTurns = 0;
  int playerBurnTurns = 0;
  int playerBleedTurns = 0;
  int playerAttackDebuffTurns = 0;
  int playerDefenseDebuffTurns = 0;
  int playerAttackDebuffValue = 0;
  int playerDefenseDebuffValue = 0;
  bool enemyIsBoss = false;
  bool enemyIsElite = false;
  String enemyNameIt = '';
  String enemyNameEn = '';
  String enemyElementId = 'neutral';

  final List<_EnemyInstance> enemyParty = [];
  final List<String> defeatedEnemyNamesIt = [];
  final List<String> defeatedEnemyNamesEn = [];
  int defeatedEnemyPowerTotal = 0;
  int defeatedEnemyExpTotal = 0;
  int defeatedBossCount = 0;
  int defeatedEliteCount = 0;

  bool valleyEncounterSeenThisRun = false;
  bool valleyTrainingUsedThisRun = false;
  bool valleyTrainingActive = false;
  bool valleyTrainingRewardClaimed = false;
  bool valleyParticipatedInFight = false;
  bool valleyBloomResolvedThisFight = false;
  bool valleySacrificedInPostea = false;
  int valleyTurnsLeft = 0;
  int valleyHp = 0;
  int valleyMaxHp = 0;
  int valleyAttack = 0;
  int valleyDefense = 0;
  int valleyBloomGuards = 0;
  int valleyTrainingTurnsLeft = 0;

  final Set<String> unlockedNpcIds = {};
  final Set<String> selectedAllyIds = {};
  final List<_GoodNpc> activeAllies = [];
  final Set<String> completedAchievementIds = {};
  bool showAchievementPanel = false;
  bool showAllyPanel = false;

  int multiEnemyBattlesWon = 0;
  int alliesRecruitedTotal = 0;
  int aoeCasts = 0;
  int oculumSkillCasts = 0;
  int merchantBuys = 0;
  int sparklingGears = 0;
  bool merchantGearsSoldThisRoom = false;
  bool peacefulMonstersMet = false;
  int eliteVaultsCleared = 0;
  int occultScrollsFound = 0;
  int elementalComboHits = 0;

  int artTechniqueCooldown = 0;
  int artTechniqueUses = 0;
  int drownedSummonTurns = 0;
  int evonestProof = 0;
  int asherContractUses = 0;
  bool asherWatched = false;
  bool woundedAllyAssistReady = false;
  bool criticalShieldActive = false;
  int criticalShieldBlocks = 0;
  int potionsUsed = 0;
  int dropsStudied = 0;
  int enemyDropsConverted = 0;

  int potionMinor = 0;
  int potionMajor = 0;
  int potionShield = 0;
  int potionOculum = 0;
  int potionCleanse = 0;
  int potionSmoke = 0;

  final List<String> enemyDropHistoryIt = [];
  final List<String> enemyDropHistoryEn = [];

  int obserInRun = 0;
  int ascensionDustInRun = 0;
  int soulShards = 0;
  int keys = 0;
  int posteaRunicMetalKg = 0;

  int runDamageBonus = 0;
  int runDefenseBonus = 0;
  int runCritBonus = 0;
  int runLifesteal = 0;
  int runHealOnExplore = 0;
  int thornWhipRollBonus = 0;
  int dodgeCharges = 0;
  int skellyGuardCharges = 0;
  int oculumCharges = 0;
  int oculumMaxCharges = 1;
  int fifiSleepActions = 0;
  int vervainBuffFloor = 0;
  int skeletonHandsHp = 0;
  int skeletonHandsMaxHp = 0;
  int cipoSerpentHp = 0;
  int cipoSerpentMaxHp = 0;
  int floralGuardCharges = 0;
  int egoShieldHp = 0;
  int egoWeaponStacks = 0;
  int egoDefenseStacks = 0;
  int relicNextRollBonus = 0;
  int tribalDanceBuffFloor = 0;
  int egoShieldBuffFloor = 0;
  int pawnHp = 0;
  int pawnMaxHp = 0;
  int pawnShield = 0;
  int pawnVolonta = 20;
  int pawnMateria = 15;
  int posteaEliteGuardHp = 0;
  int posteaEliteGuardMaxHp = 0;
  int posteaEliteGuardShield = 0;
  bool posteaEliteGuardCriticalShieldActive = false;
  int oculianKills = 0;
  int currentFloorStart = 1;
  String selectedDifficultyId = 'normal';
  double selectedDifficultyMultiplier = 1.0;
  bool tutorialRunActive = false;
  bool firstRunGateSkipped = false;
  bool floorZeroCompleted = false;
  int relicSkillUsesThisFloor = 0;
  int relicSkillUsesThisRoom = 0;
  bool minorOculianSeen = false;
  bool thousandEyesChildSeen = false;
  bool titleEventUsedThisFloor = false;
  int positiveTitleEventsSeen = 0;
  int blindSpotTitleEventsSeen = 0;
  bool baghestEyeOwned = false;
  bool baghestCultistCostume = false;
  bool oculianCostume = false;
  bool baghestBossDefeated = false;
  final Map<String, int> relicOpenLastFloor = {};

  int combo = 0;
  int killStreak = 0;
  int roomsWithoutDamage = 0;
  int fightsSinceTavernRest = 0;
  int consecutivePlayerCritsThisFight = 0;

  bool reactionAvailable = true;
  bool secondChanceUsed = false;
  bool moonSecondChance = false;
  bool mapRevealed = false;
  bool nextRoomSafe = false;
  bool nextEnemyWeakened = false;
  bool levelUpRestAvailable = false;
  bool rebirthBlessingActive = false;
  bool rareLevelUpBlessingActive = false;
  int lastPrincipianteEvolutionLevel = 1;

  int freeReforges = 1;
  int reforgeCount = 0;
  int blacksmithFavor = 0;
  int attachedDamageBonus = 0;
  int attachedDefenseBonus = 0;
  final Map<String, int> elementalResist = {};
  final List<_AttachedDrop> attachedDrops = [];
  final List<_UniqueDrop> inventoryDrops = [];

  _StarterWeapon? starterWeapon;
  _RunCostume? activeCostume;
  _DungeonArt? activeArt;
  _RelicDef? activeRelic;
  _CharacterOrigin? activeCharacterOrigin;

  final Set<String> unlockedArtIds = {};
  final Set<String> unlockedWeaponIds = {};
  final Set<String> unlockedCostumeIds = {};
  final Set<String> unlockedRelicIds = {};
  final Set<String> unlockedTitleIds = {};
  final Set<String> equippedTitleIds = {};
  final Set<String> unlockedThemePresetIds = {};
  final Map<String, int> titleLevels = {};
  final Set<int> randomTitleFloorRewardsClaimed = {};
  final Set<int> titleChoiceRoomsClaimed = {};
  final Set<String> gradeEventsSeenThisRun = {};
  final Map<String, List<String>> artSkillChoices = {};
  final Map<String, _ArtSkillProgress> artSkillProgress = {};

  String activeSkillQuestIt = '';
  String activeSkillQuestEn = '';
  String activeSkillQuestId = '';
  String activeSkillQuestTargetSkillId = '';
  int activeSkillQuestProgress = 0;
  int activeSkillQuestGoal = 0;

  String activeQuestIt = '';
  String activeQuestEn = '';
  String activeQuestId = '';
  int activeQuestProgress = 0;
  int activeQuestGoal = 0;
  bool questCompleted = false;

  final List<_DungeonChoice> eventChoices = [];
  final List<String> purchasedRelics = [];
  final List<String> runBoons = [];
  final List<String> log = [];
  final Set<int> floorSaveEventsClaimed = {};
  final Map<String, int> smallNpcActions = {};
  final Set<String> weakNpcRunEncounteredIds = {};
  final Set<int> earlyDustRoomsClaimed = {};

  bool showDungeonDetails = false;
  bool showEventChoices = true;
  String choicePanelMode = 'event';
  bool showCombatActions = true;
  bool showLogPanel = false;
  bool showArtBoard = false;
  bool showWeaponBoard = false;
  bool showSpritePanel = true;
  bool showSpriteCodex = false;
  bool classicCombatView = false;
  bool showCombatHudDetails = false;
  bool quickEyeCollapsed = false;
  int playerSpriteShape = 0;
  int playerSpriteAccent = 0;
  bool trapMiniGameActive = false;
  int trapPlayerLane = 1;
  int trapStep = 0;
  int trapHits = 0;
  int trapReward = 0;
  int trapStepsTotal = 6;
  int trapFocusCharges = 0;
  int trapBestCombo = 0;
  int trapCurrentCombo = 0;
  bool oculianAllianceActive = false;
  bool get hasOculianPact {
    final originId = activeCharacterOrigin?.id;
    return oculianAllianceActive ||
        originId == 'male_oculian_cultist' ||
        originId == 'female_oculian_cultist' ||
        selectedSkinId == 'oculian' ||
        oculianCostume;
  }

  bool gufusUsedInPreviousRun = false;
  bool gufusUsedThisRun = false;
  bool posteaGufusEventCompleted = false;
  bool posteaGufusEventActive = false;
  String posteaGufusEventPhase = '';
  int posteaScientistTurnCounter = 0;
  bool posteaScientistEnhanced = false;
  bool monsterVillageFightActive = false;
  final Set<String> selectedRunArtIds = {};
  int trapRevealedStep = -1;
  final List<String> quickTileOrder = [
    'party',
    'costume',
    'relic',
    'art',
    'titles',
    'bag',
    'kooba',
    'drowned',
  ];

  bool merchantActionUsedThisRoom = false;
  bool blacksmithActionUsedThisRoom = false;
  bool dropActionUsedThisRoom = false;
  bool restActionUsedThisRoom = false;
  bool tavernMealUsedThisRoom = false;
  bool tavernMerchantActionUsedThisRoom = false;
  bool tavernBlacksmithActionUsedThisRoom = false;
  bool tavernSleepUsedThisRoom = false;

  int oculumSpento = 0;
  bool endRunOculumPaid = false;

  String textIt =
      'Il dungeon è chiuso. Una palpebra di pietra attende che tu la tocchi.';
  String textEn =
      'The dungeon is closed. A stone eyelid waits for you to touch it.';

  static const List<_DungeonThemeUnlockDef> _themeUnlocks = [
    _DungeonThemeUnlockDef(
      id: 'blood_court',
      nameIt: 'Corte di sangue',
      nameEn: 'Blood court',
      color: Color(0xFFB93A46),
    ),
    _DungeonThemeUnlockDef(
      id: 'witch_glass',
      nameIt: 'Vetro strega',
      nameEn: 'Witch glass',
      color: Color(0xFF42C78F),
    ),
    _DungeonThemeUnlockDef(
      id: 'moon_iron',
      nameIt: 'Ferro lunare',
      nameEn: 'Moon iron',
      color: Color(0xFF7D92B8),
    ),
    _DungeonThemeUnlockDef(
      id: 'ash_oracle',
      nameIt: 'Oracolo di cenere',
      nameEn: 'Ash oracle',
      color: Color(0xFF9B8A72),
    ),
    _DungeonThemeUnlockDef(
      id: 'void_liturgy',
      nameIt: 'Liturgia del vuoto',
      nameEn: 'Void liturgy',
      color: Color(0xFF775CF0),
    ),
    _DungeonThemeUnlockDef(
      id: 'postea_bloom',
      nameIt: 'Fioritura di Postea',
      nameEn: 'Postea bloom',
      color: Color(0xFF8FB7FF),
    ),
    _DungeonThemeUnlockDef(
      id: 'karma_duality',
      nameIt: 'Bilancia del karma',
      nameEn: 'Karma scales',
      color: Color(0xFF2DCB98),
    ),
    _DungeonThemeUnlockDef(
      id: 'monster_lantern',
      nameIt: 'Lanterna dei mostri',
      nameEn: 'Monster lantern',
      color: Color(0xFF4F6FD8),
    ),
    _DungeonThemeUnlockDef(
      id: 'phobia_dark',
      nameIt: 'Phobia',
      nameEn: 'Phobia',
      color: Color(0xFF8A2D3E),
    ),
  ];

  static const List<_RunCostume> _runCostumes = [
    _RunCostume(
      id: 'ragged_oculum_cloak',
      nameIt: 'Mantello Sfilacciato dell’Oculum',
      nameEn: 'Ragged Oculum Cloak',
      descIt:
          'Costume base. Stoffa nera, orlo viola, un occhio cucito male. +20 HP, +12 Scudo, +1 Oculum.',
      descEn:
          'Base costume. Black cloth, violet hem, a badly sewn eye. +20 HP, +12 Shield, +1 Oculum.',
      hpBonus: 20,
      shieldBonus: 12,
      defenseBonus: 0,
      damageBonus: 0,
      oculumBonus: 1,
      critBonus: 0,
      elementId: 'oculum',
      unlockedByDefault: true,
    ),
    _RunCostume(
      id: 'bone_button_armor',
      nameIt: 'Armatura dei Bottoni d’Osso',
      nameEn: 'Bone Button Armor',
      descIt:
          'Piccola armatura gotica con bottoni d’osso e cuciture dure. +10 HP, +30 Scudo, +3 Difesa.',
      descEn:
          'Small gothic armor with bone buttons and hard stitches. +10 HP, +30 Shield, +3 Defense.',
      hpBonus: 10,
      shieldBonus: 30,
      defenseBonus: 3,
      damageBonus: 0,
      oculumBonus: 0,
      critBonus: 0,
      elementId: 'bone',
      unlockedByDefault: true,
    ),
    _RunCostume(
      id: 'starlit_vagrant_coat',
      nameIt: 'Cappotto del Vagabondo Stellato',
      nameEn: 'Starlit Vagrant Coat',
      descIt:
          'Un cappotto leggero pieno di piccole stelle finte. +2 Danno, +5 Critico, +1 schivata.',
      descEn:
          'A light coat full of tiny fake stars. +2 Damage, +5 Critical, +1 dodge.',
      hpBonus: 0,
      shieldBonus: 10,
      defenseBonus: 0,
      damageBonus: 2,
      oculumBonus: 0,
      critBonus: 5,
      elementId: 'star',
      unlockedByDefault: true,
    ),
    _RunCostume(
      id: 'moss_choir_garb',
      nameIt: 'Abito del Coro di Muschio',
      nameEn: 'Moss Choir Garb',
      descIt:
          'Abito vivo e umido, sussurra piano quando entri in una stanza vuota. +25 HP, +1 cura/esplora, +1 Difesa.',
      descEn:
          'A living damp garb, whispering when you enter an empty room. +25 HP, +1 heal/explore, +1 Defense.',
      hpBonus: 25,
      shieldBonus: 8,
      defenseBonus: 1,
      damageBonus: 0,
      oculumBonus: 0,
      critBonus: 0,
      elementId: 'flora',
      unlockedByDefault: true,
    ),
    _RunCostume(
      id: 'baghest_cultist_armor',
      nameIt: 'Costume da Cultista di Baghest',
      nameEn: 'Baghest Cultist Costume',
      descIt:
          'Maschera e mantello cultista. Gli élite esitano. +3 Danno, +3 Difesa, +1 Oculum.',
      descEn:
          'Cultist mask and cloak. Elites hesitate. +3 Damage, +3 Defense, +1 Oculum.',
      hpBonus: 15,
      shieldBonus: 18,
      defenseBonus: 3,
      damageBonus: 3,
      oculumBonus: 1,
      critBonus: 3,
      elementId: 'shadow',
    ),
    _RunCostume(
      id: 'oculian_eye_mantle',
      nameIt: 'Mantello dell’Oculiano',
      nameEn: 'Oculian Eye Mantle',
      descIt:
          'Molti occhi cuciti sotto il mantello. Raddoppia l’Oculum iniziale. +2 Danno, +2 Difesa.',
      descEn:
          'Many eyes sewn under the mantle. Doubles starting Oculum. +2 Damage, +2 Defense.',
      hpBonus: 12,
      shieldBonus: 20,
      defenseBonus: 2,
      damageBonus: 2,
      oculumBonus: 2,
      critBonus: 2,
      elementId: 'oculum',
    ),

    _RunCostume(
      id: 'oculian_eye_armor',
      nameIt: 'Armatura dell’Oculiano',
      nameEn: 'Oculian Eye Armor',
      descIt:
          'Armatura viola, osso e palpebre metalliche. Completa i set Oculum con lama e scudo. +18 HP, +34 Scudo, +4 Difesa, +2 Danno, +2 Oculum.',
      descEn:
          'Violet, bone and metal-eyelid armor. Completes Oculum sets with blade and shield. +18 HP, +34 Shield, +4 Defense, +2 Damage, +2 Oculum.',
      hpBonus: 18,
      shieldBonus: 34,
      defenseBonus: 4,
      damageBonus: 2,
      oculumBonus: 2,
      critBonus: 4,
      elementId: 'oculum',
      unlockedByDefault: true,
    ),

    _RunCostume(
      id: 'vitalium_rebirth_gown',
      nameIt: 'Veste di Vitalium Ridefinito',
      nameEn: 'Refined Vitalium Gown',
      descIt:
          'Cura tutta la vita dopo ogni fight, ma lo Scudo ottenuto dai fight è dimezzato. Sembra gentile, ma chiede pelle al posto del ferro.',
      descEn:
          'Heals all HP after every fight, but Shield gained from fights is halved. It seems kind, but asks for skin instead of iron.',
      hpBonus: 35,
      shieldBonus: 0,
      defenseBonus: -1,
      damageBonus: 0,
      oculumBonus: 1,
      critBonus: 0,
      elementId: 'flora',
    ),
    _RunCostume(
      id: 'evonest_triple_shell',
      nameIt: 'Carapace delle Tre Teste di Evonest',
      nameEn: 'Evonest Three-Head Shell',
      descIt:
          'Un guscio marino con tre respiri dentro: Dyro, Smarg e Leoness parlano piano. +50 HP, +3 Difesa, acqua e corruzione fanno meno paura.',
      descEn:
          'A sea shell with three breaths inside: Dyro, Smarg and Leoness whisper. +50 HP, +3 Defense, water and corruption feel less frightening.',
      hpBonus: 50,
      shieldBonus: 18,
      defenseBonus: 3,
      damageBonus: 0,
      oculumBonus: 1,
      critBonus: 0,
      elementId: 'water',
    ),
    _RunCostume(
      id: 'asher_burnt_contract',
      nameIt: 'Giacca del Contratto di Asher',
      nameEn: 'Asher Burnt Contract Jacket',
      descIt:
          'Un contratto cucito nella fodera. I critici odorano di brace. +4 Danno, +6 Critico, +1 Oculum.',
      descEn:
          'A contract sewn into the lining. Critical hits smell like ember. +4 Damage, +6 Critical, +1 Oculum.',
      hpBonus: 0,
      shieldBonus: 12,
      defenseBonus: 0,
      damageBonus: 4,
      oculumBonus: 1,
      critBonus: 6,
      elementId: 'fire',
    ),
    _RunCostume(
      id: 'drowned_city_robe',
      nameIt: 'Tunica degli Affogati di Commercio',
      nameEn: 'Drowned Trade Robe',
      descIt:
          'Tessuto di acqua vecchia e monete bagnate. Dopo un fight può far restare fino a 3 Affogati temporanei nel party; 4 con Romanzo. +2 Oculum, +2 Difesa.',
      descEn:
          'Old water and wet coins woven together. After a fight it can keep up to 3 Temporary Drowned in the party; 4 with the Novel. +2 Oculum, +2 Defense.',
      hpBonus: 15,
      shieldBonus: 16,
      defenseBonus: 2,
      damageBonus: 0,
      oculumBonus: 2,
      critBonus: 0,
      elementId: 'water',
    ),
    _RunCostume(
      id: 'hidenas_thousand_ember_uniform',
      nameIt: 'Uniforme Hideana delle Mille Braci',
      nameEn: 'Hidean Thousand-Ember Uniform',
      descIt:
          'Uniforme ignifuga, quasi troppo pulita. Ogni fuoco ti riconosce come parente lontano. +5 Danno, +2 Difesa.',
      descEn:
          'Fireproof uniform, almost too clean. Every flame recognizes you as distant kin. +5 Damage, +2 Defense.',
      hpBonus: 10,
      shieldBonus: 18,
      defenseBonus: 2,
      damageBonus: 5,
      oculumBonus: 0,
      critBonus: 2,
      elementId: 'fire',
    ),
    _RunCostume(
      id: 'vapium_vapor_plate',
      nameIt: 'Corazza di Vapium Compresso',
      nameEn: 'Compressed Vapium Plate',
      descIt:
          'Si fa nebbia quando hai paura e pietra quando devi restare. +45 Scudo, +4 Difesa, +1 Materia.',
      descEn:
          'It becomes mist when you fear and stone when you must stay. +45 Shield, +4 Defense, +1 Materia.',
      hpBonus: 10,
      shieldBonus: 45,
      defenseBonus: 4,
      damageBonus: 0,
      oculumBonus: 0,
      critBonus: 0,
      elementId: 'vapium',
    ),
    _RunCostume(
      id: 'postea_elite_armor',
      nameIt: 'Armatura Elite Postea',
      nameEn: 'Postea Elite Armor',
      descIt:
          'Armatura avanzata dei soldati elite di Postea. +25 HP, +50 Scudo, +4 Difesa, +3 Danno. Attiva Scudo Critico a inizio run.',
      descEn:
          'Advanced armor worn by Postea elite soldiers. +25 HP, +50 Shield, +4 Defense, +3 Damage. Activates Critical Shield at run start.',
      hpBonus: 25,
      shieldBonus: 50,
      defenseBonus: 4,
      damageBonus: 3,
      oculumBonus: 0,
      critBonus: 4,
      elementId: 'postea',
    ),
    _RunCostume(
      id: 'moonhills_lunium_veil',
      nameIt: 'Velo di Lunium delle MoonHills',
      nameEn: 'MoonHills Lunium Veil',
      descIt:
          'Un velo rosa-lunare che non illumina: ricorda. +3 Oculum, +5 Critico, +1 schivata.',
      descEn:
          'A pink lunar veil that does not shine: it remembers. +3 Oculum, +5 Critical, +1 dodge.',
      hpBonus: 0,
      shieldBonus: 14,
      defenseBonus: 0,
      damageBonus: 1,
      oculumBonus: 3,
      critBonus: 5,
      elementId: 'moon',
    ),
    _RunCostume(
      id: 'obser_merchant_jacket',
      nameIt: 'Giacca del Mercante di Obser',
      nameEn: 'Obser Merchant Jacket',
      descIt:
          'Tasche piccole, occhi incisi e una morale elastica. Parti con +18 Obser e vendi meglio i drop.',
      descEn:
          'Small pockets, engraved eyes and elastic morals. Start with +18 Obser and sell drops better.',
      hpBonus: 5,
      shieldBonus: 8,
      defenseBonus: 0,
      damageBonus: 0,
      oculumBonus: 0,
      critBonus: 0,
      elementId: 'neutral',
    ),
  ];

  static const List<_StarterWeapon> _starterWeapons = [
    _StarterWeapon(
      id: 'obser_sword',
      nameIt: 'Spada degli Obser Incisi',
      nameEn: 'Engraved Obser Sword',
      descIt: '+5 danni. Lama semplice con un occhio inciso nella pietra.',
      descEn: '+5 damage. Simple blade with an eye engraved in stone.',
      damageBonus: 5,
      defenseBonus: 0,
      shieldBonus: 15,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'neutral',
      unlockedByDefault: true,
    ),
    _StarterWeapon(
      id: 'eyelid_shield',
      nameIt: 'Scudo della Palpebra',
      nameEn: 'Eyelid Shield',
      descIt: '+2 difesa, +1 danno, +35 Scudo. Si chiude quando hai paura.',
      descEn: '+2 defense, +1 damage, +35 Shield. It closes when you fear.',
      damageBonus: 1,
      defenseBonus: 2,
      shieldBonus: 35,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'earth',
      unlockedByDefault: true,
    ),
    _StarterWeapon(
      id: 'oculum_blade_shield_set',
      nameIt: 'Lama e Scudo dell’Oculum',
      nameEn: 'Oculum Blade and Shield',
      descIt:
          '+4 danni, +3 difesa, +35 Scudo, +1 Oculum. Set visivo con lama impugnata e scudo da fight.',
      descEn:
          '+4 damage, +3 defense, +35 Shield, +1 Oculum. Visual set with held blade and fight shield.',
      damageBonus: 4,
      defenseBonus: 3,
      shieldBonus: 35,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'oculum',
      unlockedByDefault: true,
    ),
    _StarterWeapon(
      id: 'hollow_oculum_staff',
      nameIt: 'Bastone dell’Oculum Cavo',
      nameEn: 'Hollow Oculum Staff',
      descIt:
          '+1 danno, +2 Oculum, +2 cariche Oculum. Un foro osserva al posto tuo.',
      descEn:
          '+1 damage, +2 Oculum, +2 Oculum charges. A hollow watches for you.',
      damageBonus: 1,
      defenseBonus: 0,
      shieldBonus: 15,
      oculumBonus: 2,
      oculumCharges: 2,
      elementId: 'moon',
      unlockedByDefault: true,
    ),
    _StarterWeapon(
      id: 'hidenas_saber',
      nameIt: 'Sciabola Bruciata di Hidenas',
      nameEn: 'Burnt Saber of Hidenas',
      descIt:
          '+4 danni fuoco. Sembra spenta, ma odora ancora di città bruciata.',
      descEn:
          '+4 fire damage. It looks unlit, but still smells like a burned city.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'fire',
    ),
    _StarterWeapon(
      id: 'tidal_needle',
      nameIt: 'Ago della Marea Bendata',
      nameEn: 'Blindfolded Tide Needle',
      descIt: '+2 danni acqua, +1 difesa. Cura ferite piccole mentre trema.',
      descEn:
          '+2 water damage, +1 defense. It heals small wounds while shaking.',
      damageBonus: 2,
      defenseBonus: 1,
      shieldBonus: 20,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'water',
    ),
    _StarterWeapon(
      id: 'black_mimic_dagger',
      nameIt: 'Pugnale del Mimic Nero',
      nameEn: 'Black Mimic Dagger',
      descIt: '+4 danni ombra, +1 schivata iniziale. A volte ride nella borsa.',
      descEn:
          '+4 shadow damage, +1 starting dodge. Sometimes it laughs in your bag.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'shadow',
    ),
    _StarterWeapon(
      id: 'vapium_hammer',
      nameIt: 'Martello di Vapium Muto',
      nameEn: 'Mute Vapium Hammer',
      descIt: '+2 danni, +2 difesa, +25 Scudo. Condensa quando menti.',
      descEn: '+2 damage, +2 defense, +25 Shield. It condenses when you lie.',
      damageBonus: 2,
      defenseBonus: 2,
      shieldBonus: 25,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'vapium',
    ),
    _StarterWeapon(
      id: 'storm_lance',
      nameIt: 'Lancia del Fulmine Sepolto',
      nameEn: 'Buried Lightning Lance',
      descIt: '+5 danni fulmine. Colpisce prima che tu finisca il pensiero.',
      descEn: '+5 lightning damage. It strikes before your thought ends.',
      damageBonus: 5,
      defenseBonus: 0,
      shieldBonus: 8,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'lightning',
    ),
    _StarterWeapon(
      id: 'sound_knife',
      nameIt: 'Coltello del Suono Cucito',
      nameEn: 'Sewn Sound Knife',
      descIt: '+3 danni suono, +5 critico. Urla senza aprire bocca.',
      descEn: '+3 sound damage, +5 crit. It screams without opening its mouth.',
      damageBonus: 3,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'sound',
    ),
    _StarterWeapon(
      id: 'crystal_maul',
      nameIt: 'Mazza di Cristallo Fumè',
      nameEn: 'Smoky Crystal Maul',
      descIt:
          '+3 danni cristallo, +1 difesa. Riflette una versione triste di te.',
      descEn:
          '+3 crystal damage, +1 defense. It reflects a sad version of you.',
      damageBonus: 3,
      defenseBonus: 1,
      shieldBonus: 18,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'crystal',
    ),
    _StarterWeapon(
      id: 'blood_hook',
      nameIt: 'Uncino del Sangue Nero',
      nameEn: 'Black Blood Hook',
      descIt: '+3 danni sangue, +1 furto vita. Non gocciola: ricorda.',
      descEn: '+3 blood damage, +1 lifesteal. It does not drip: it remembers.',
      damageBonus: 3,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'blood',
    ),
    _StarterWeapon(
      id: 'ice_chime',
      nameIt: 'Campana del Gelo Sordo',
      nameEn: 'Deaf Ice Chime',
      descIt: '+2 danni gelo, +2 difesa. Suona solo quando nessuno ascolta.',
      descEn: '+2 ice damage, +2 defense. It rings only when nobody listens.',
      damageBonus: 2,
      defenseBonus: 2,
      shieldBonus: 20,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'ice',
    ),

    _StarterWeapon(
      id: 'boomerang_psico',
      nameIt: 'Boomerang Psico della Palpebra Storta',
      nameEn: 'Crooked Eyelid Psyche Boomerang',
      descIt: '+3 danni psico. Torna indietro solo se il pensiero non mente.',
      descEn: '+3 psyche damage. It returns only if the thought does not lie.',
      damageBonus: 3,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'psyche',
    ),
    _StarterWeapon(
      id: 'lava_chakram',
      nameIt: 'Chakram di Lava Benedetta Male',
      nameEn: 'Badly Blessed Lava Chakram',
      descIt: '+4 danni lava. Gira come una corona troppo calda.',
      descEn: '+4 lava damage. It spins like a crown too hot to wear.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'lava',
    ),
    _StarterWeapon(
      id: 'bone_flail',
      nameIt: 'Mazzafrusto delle Ossa Educate',
      nameEn: 'Polite Bone Flail',
      descIt: '+3 danni osso, +1 difesa. Chiede scusa dopo ogni frattura.',
      descEn: '+3 bone damage, +1 defense. It apologizes after every fracture.',
      damageBonus: 3,
      defenseBonus: 1,
      shieldBonus: 18,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'bone',
    ),
    _StarterWeapon(
      id: 'gravity_rapier',
      nameIt: 'Stocco della Gravità Cieca',
      nameEn: 'Blind Gravity Rapier',
      descIt: '+3 danni gravità, +1 Oculum. Affonda verso l’alto.',
      descEn: '+3 gravity damage, +1 Oculum. It thrusts upward by falling.',
      damageBonus: 3,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'gravity',
    ),
    _StarterWeapon(
      id: 'nullum_scythe',
      nameIt: 'Falce Null della Storia Cancellata',
      nameEn: 'Null Scythe of the Erased Story',
      descIt: '+5 danni Null. Dove passa, manca una frase.',
      descEn: '+5 Null damage. Where it passes, a sentence is missing.',
      damageBonus: 5,
      defenseBonus: 0,
      shieldBonus: 6,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'nullum',
    ),
    _StarterWeapon(
      id: 'dream_morningstar',
      nameIt: 'Stella del Mattino Sognata Male',
      nameEn: 'Badly Dreamed Morning Star',
      descIt: '+3 danni sogno, +2 Scudo a ogni reforge.',
      descEn: '+3 dream damage, +2 Shield on each reforge.',
      damageBonus: 3,
      defenseBonus: 1,
      shieldBonus: 20,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'dream',
    ),
    _StarterWeapon(
      id: 'metal_greatsword',
      nameIt: 'Spadone di Metallo Slime Corrotto',
      nameEn: 'Corrupted Slime Metal Greatsword',
      descIt: '+5 danni metallo, -nessuna grazia. Pesante come un rimorso.',
      descEn: '+5 metal damage, no mercy. Heavy as remorse.',
      damageBonus: 5,
      defenseBonus: 1,
      shieldBonus: 10,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'metal',
    ),
    _StarterWeapon(
      id: 'root_sickle_pair',
      nameIt: 'Doppia Falce di Radice Rosa',
      nameEn: 'Twin Pink Root Sickles',
      descIt: '+3 danni radice, +1 schivata. Pucciose, ma non innocenti.',
      descEn: '+3 root damage, +1 dodge. Cute, but not innocent.',
      damageBonus: 3,
      defenseBonus: 0,
      shieldBonus: 14,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'flora',
    ),
    _StarterWeapon(
      id: 'sweet_patalpa_shovel',
      nameIt: 'Pala del Patalpa Dolce',
      nameEn: 'Sweet Patalpa Shovel',
      descIt:
          '+4 VC tradotto in +4 danni, +1 difesa. Puoi usare Palata: se critta applica Stun x critico e +2 danni x livello, cooldown 5 turni narrativo. Punto cieco: -2 percezione.',
      descEn:
          '+4 VC translated as +4 damage, +1 defense. You may use Shovel Slam: on critical applies Stun x critical and +2 damage x level, narrative cooldown 5 turns. Blind spot: -2 perception.',
      damageBonus: 4,
      defenseBonus: 1,
      shieldBonus: 16,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'flora',
    ),

    _StarterWeapon(
      id: 'silver_boomerang',
      nameIt: 'Boomerang d’Argento',
      nameEn: 'Silver Boomerang',
      descIt:
          '+4 danni metallo, +1 Oculum. Rimbalza una volta se ci sono più nemici.',
      descEn:
          '+4 metal damage, +1 Oculum. Bounces once if there are multiple enemies.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'metal',
    ),
    _StarterWeapon(
      id: 'combattimento_mani_nude',
      nameIt: 'Combattimento a Mani Nude',
      nameEn: 'Bare-Hand Combat',
      descIt:
          '+12 danni, +2 difesa, +2 critico. Arma del primo villaggio: ogni attacco concatena un colpo extra e apre le Martial Art.',
      descEn:
          '+12 damage, +2 defense, +2 critical. First village weapon: every attack chains an extra hit and opens Martial Arts.',
      damageBonus: 12,
      defenseBonus: 2,
      shieldBonus: 0,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'neutral',
    ),
    _StarterWeapon(
      id: 'postea_auto_rifle',
      nameIt: 'Fucile Automatico di Postea',
      nameEn: 'Postea Automatic Rifle',
      descIt:
          '+7 danni Postea, +3 critico. Arma automatica del futuro chiuso: spara prima che il domani abbia il permesso di esistere.',
      descEn:
          '+7 Postea damage, +3 critical. Automatic weapon from the sealed future: it fires before tomorrow has permission to exist.',
      damageBonus: 7,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'postea',
    ),
    _StarterWeapon(
      id: 'postea_grenades',
      nameIt: 'Granate di Postea',
      nameEn: 'Postea Grenades',
      descIt:
          '+4 danni Postea. Arma principale speciale: Attacca diventa VC AoE e non consuma Oculum.',
      descEn:
          '+4 Postea damage. Special main weapon: Attack becomes VC AoE and costs no Oculum.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 8,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'postea',
    ),
    _StarterWeapon(
      id: 'sun_chakram',
      nameIt: 'Chakram del Sole',
      nameEn: 'Sun Chakram',
      descIt: '+4 danni sole. Aumenta i danni contro boss.',
      descEn: '+4 sun damage. Increases damage against bosses.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'sun',
    ),
    _StarterWeapon(
      id: 'dream_sabre',
      nameIt: 'Sciabola del Sogno',
      nameEn: 'Dream Sabre',
      descIt:
          '+3 sogno, +2 difesa. Riduce il primo colpo subito in ogni fight.',
      descEn:
          '+3 dream, +2 defense. Reduces the first hit taken in each fight.',
      damageBonus: 3,
      defenseBonus: 2,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'dream',
    ),
    _StarterWeapon(
      id: 'psyche_maul',
      nameIt: 'Maglio Psico',
      nameEn: 'Psyche Maul',
      descIt: '+5 psico. Ogni tanto indebolisce il bersaglio.',
      descEn: '+5 psyche. Sometimes weakens the target.',
      damageBonus: 5,
      defenseBonus: 0,
      shieldBonus: 8,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'psyche',
    ),
    _StarterWeapon(
      id: 'root_chain',
      nameIt: 'Catena di Radice',
      nameEn: 'Root Chain',
      descIt: '+3 radice, +1 schivata. Buona contro gruppi.',
      descEn: '+3 root, +1 dodge. Good against groups.',
      damageBonus: 3,
      defenseBonus: 0,
      shieldBonus: 15,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'flora',
    ),
    _StarterWeapon(
      id: 'null_halberd',
      nameIt: 'Alabarda Null',
      nameEn: 'Null Halberd',
      descIt: '+5 Null, +1 difesa. Ignora parte della difesa nemica.',
      descEn: '+5 Null, +1 defense. Ignores part of enemy defense.',
      damageBonus: 5,
      defenseBonus: 1,
      shieldBonus: 8,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'nullum',
    ),
    _StarterWeapon(
      id: 'lava_star',
      nameIt: 'Stella di Lava',
      nameEn: 'Lava Star',
      descIt: '+5 lava, +10 Scudo. Applica bruciatura più spesso.',
      descEn: '+5 lava, +10 Shield. Applies burn more often.',
      damageBonus: 5,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'lava',
    ),
    _StarterWeapon(
      id: 'moon_needle',
      nameIt: 'Ago Lunare',
      nameEn: 'Moon Needle',
      descIt: '+2 luna, +3 Oculum, +1 carica. Migliora le cure.',
      descEn: '+2 moon, +3 Oculum, +1 charge. Improves healing.',
      damageBonus: 2,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 3,
      oculumCharges: 1,
      elementId: 'moon',
    ),

    _StarterWeapon(
      id: 'evonest_three_head_scale',
      nameIt: 'Scaglia di Evonest',
      nameEn: 'Evonest Scale',
      descIt:
          '+3 acqua, +2 difesa, +1 Oculum. Se hai provato bontà a Evonest, migliora le cure.',
      descEn:
          '+3 water, +2 defense, +1 Oculum. If you proved goodness to Evonest, healing improves.',
      damageBonus: 3,
      defenseBonus: 2,
      shieldBonus: 18,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'water',
    ),
    _StarterWeapon(
      id: 'dyro_sea_lion_spear',
      nameIt: 'Lancia di Dyro',
      nameEn: 'Dyro Spear',
      descIt: '+4 acqua, +1 schivata. Colpisce meglio i bersagli indeboliti.',
      descEn: '+4 water, +1 dodge. Strikes weakened targets better.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'water',
    ),
    _StarterWeapon(
      id: 'smarg_jaw_blade',
      nameIt: 'Lama di Smarg',
      nameEn: 'Smarg Blade',
      descIt: '+5 sangue/acqua. Contro nemici corrotti aumenta furto vita.',
      descEn:
          '+5 blood/water. Against corrupted enemies it improves lifesteal.',
      damageBonus: 5,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'blood',
    ),
    _StarterWeapon(
      id: 'leoness_calm_ring',
      nameIt: 'Anello di Leoness',
      nameEn: 'Leoness Ring',
      descIt: '+2 Oculum, +2 difesa. Calma la corruzione e protegge nei boss.',
      descEn:
          '+2 Oculum, +2 defense. Calms corruption and protects during bosses.',
      damageBonus: 1,
      defenseBonus: 2,
      shieldBonus: 24,
      oculumBonus: 2,
      oculumCharges: 1,
      elementId: 'moon',
    ),
    _StarterWeapon(
      id: 'asher_contract_brand',
      nameIt: 'Marchio di Asher',
      nameEn: 'Asher Brand',
      descIt:
          '+4 fuoco. I critici fisici possono bruciare se hai pagato il contratto.',
      descEn:
          '+4 fire. Physical critical hits may burn if you paid the contract.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 10,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'fire',
    ),
    _StarterWeapon(
      id: 'hidean_trade_gadget',
      nameIt: 'Gadget Hideano',
      nameEn: 'Hidean Gadget',
      descIt:
          '+1 a tutto nella run. Debole ma comodo, nato in una città di commercio.',
      descEn:
          '+1 to everything in the run. Weak but useful, born in a trade city.',
      damageBonus: 1,
      defenseBonus: 1,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'neutral',
    ),

    _StarterWeapon(
      id: 'blind_orbit_chakram',
      nameIt: 'Chakram dell’Orbita Cieca',
      nameEn: 'Blind Orbit Chakram',
      descIt:
          '+4 danni, +1 Oculum, +1 carica. Pensato per colpire in cerchio: ottimo con AoE VC.',
      descEn:
          '+4 damage, +1 Oculum, +1 charge. Made to strike in circles: excellent with VC AoE.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 14,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'gravity',
    ),

    _StarterWeapon(
      id: 'expert_oculum_scythe',
      nameIt: 'Falce dell’Esperto di Oculum',
      nameEn: 'Oculum Expert Scythe',
      descIt:
          '+9 danni, +2 Oculum. Ogni taglio sembra una lezione imparata male.',
      descEn:
          '+9 damage, +2 Oculum. Every cut feels like a lesson learned wrong.',
      damageBonus: 9,
      defenseBonus: 0,
      shieldBonus: 18,
      oculumBonus: 2,
      oculumCharges: 1,
      elementId: 'oculum',
    ),
    _StarterWeapon(
      id: 'expert_pupil_maul',
      nameIt: 'Maglio della Pupilla Antica',
      nameEn: 'Ancient Pupil Maul',
      descIt: '+6 danni, +4 difesa, +40 Scudo.',
      descEn: '+6 damage, +4 defense, +40 Shield.',
      damageBonus: 6,
      defenseBonus: 4,
      shieldBonus: 40,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'earth',
    ),
    _StarterWeapon(
      id: 'expert_star_chakram',
      nameIt: 'Chakram della Stella Bassa',
      nameEn: 'Low Star Chakram',
      descIt: '+7 danni, +6 critico, +1 schivata.',
      descEn: '+7 damage, +6 critical, +1 dodge.',
      damageBonus: 7,
      defenseBonus: 0,
      shieldBonus: 16,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'star',
    ),
    _StarterWeapon(
      id: 'expert_core_rapier',
      nameIt: 'Stocco del Core Viola',
      nameEn: 'Purple Core Rapier',
      descIt: '+5 danni, +3 Oculum, perfora le debolezze.',
      descEn: '+5 damage, +3 Oculum, pierces weaknesses.',
      damageBonus: 5,
      defenseBonus: 1,
      shieldBonus: 20,
      oculumBonus: 3,
      oculumCharges: 1,
      elementId: 'poison',
    ),
    _StarterWeapon(
      id: 'expert_moon_flail',
      nameIt: 'Mazzafrusto della Luna Nervosa',
      nameEn: 'Nervous Moon Flail',
      descIt: '+8 danni luna, +2 difesa, +1 carica.',
      descEn: '+8 moon damage, +2 defense, +1 charge.',
      damageBonus: 8,
      defenseBonus: 2,
      shieldBonus: 22,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'moon',
    ),
    _StarterWeapon(
      id: 'expert_obser_boomerang',
      nameIt: 'Boomerang dell’Obser Sepolto',
      nameEn: 'Buried Obser Boomerang',
      descIt: '+6 danni, torna con +1 Obser dopo fight difficili.',
      descEn: '+6 damage, returns with +1 Obser after hard fights.',
      damageBonus: 6,
      defenseBonus: 1,
      shieldBonus: 15,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'neutral',
    ),

    _StarterWeapon(
      id: 'leaf_boomerang',
      nameIt: 'Boomerang a Foglia',
      nameEn: 'Leaf Boomerang',
      descIt:
          '+3 danni natura, +1 difesa. Torna indietro con una foglia nuova, anche quando non dovrebbe.',
      descEn:
          '+3 nature damage, +1 defense. It returns with a new leaf, even when it should not.',
      damageBonus: 3,
      defenseBonus: 1,
      shieldBonus: 18,
      oculumBonus: 0,
      oculumCharges: 1,
      elementId: 'flora',
      unlockedByDefault: true,
    ),
    _StarterWeapon(
      id: 'kitty_slime_sling',
      nameIt: 'Fionda Kitty Slime',
      nameEn: 'Kitty Slime Sling',
      descIt:
          '+2 danni, +2 critico. Morbida, imbarazzante, sorprendentemente precisa.',
      descEn:
          '+2 damage, +2 critical. Soft, embarrassing, surprisingly precise.',
      damageBonus: 2,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'slime',
      unlockedByDefault: true,
    ),
    _StarterWeapon(
      id: 'kooba_shiny_hook',
      nameIt: 'Uncino Scintillante di Kooba',
      nameEn: 'Kooba Glimmer Hook',
      descIt:
          '+2 danni, +1 Materia, +6 Obser iniziali se trovi un mercante presto.',
      descEn:
          '+2 damage, +1 Materia, +6 starting Obser if you find a merchant early.',
      damageBonus: 2,
      defenseBonus: 1,
      shieldBonus: 10,
      oculumBonus: 0,
      oculumCharges: 0,
      elementId: 'metal',
      unlockedByDefault: true,
    ),
    _StarterWeapon(
      id: 'arcane_dash_blade',
      nameIt: 'Lama del Passo Arcano',
      nameEn: 'Arcane Step Blade',
      descIt:
          '+4 danni, +2 critico, +1 schivata. Scatta come un incantesimo da arena.',
      descEn: '+4 damage, +2 critical, +1 dodge. Dashes like an arena spell.',
      damageBonus: 4,
      defenseBonus: 0,
      shieldBonus: 12,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'lightning',
    ),
    _StarterWeapon(
      id: 'frost_ring_gauntlets',
      nameIt: 'Guanti degli Anelli di Gelo',
      nameEn: 'Frost Ring Gauntlets',
      descIt: '+3 danni gelo, +2 difesa. Ogni parata lascia un cerchio freddo.',
      descEn: '+3 ice damage, +2 defense. Every guard leaves a cold ring.',
      damageBonus: 3,
      defenseBonus: 2,
      shieldBonus: 18,
      oculumBonus: 1,
      oculumCharges: 0,
      elementId: 'ice',
    ),
    _StarterWeapon(
      id: 'ember_orbit_staff',
      nameIt: 'Bastone dell Orbita di Brace',
      nameEn: 'Ember Orbit Staff',
      descIt: '+3 fuoco, +2 Oculum. Le braci girano intorno alla mano.',
      descEn: '+3 fire, +2 Oculum. Embers orbit around the hand.',
      damageBonus: 3,
      defenseBonus: 0,
      shieldBonus: 14,
      oculumBonus: 2,
      oculumCharges: 1,
      elementId: 'fire',
    ),
    _StarterWeapon(
      id: 'tidal_combo_tonfa',
      nameIt: 'Tonfa della Combo di Marea',
      nameEn: 'Tidal Combo Tonfa',
      descIt: '+4 acqua, +1 difesa. Migliora gli scontri con più nemici.',
      descEn: '+4 water, +1 defense. Better against multi-enemy fights.',
      damageBonus: 4,
      defenseBonus: 1,
      shieldBonus: 14,
      oculumBonus: 1,
      oculumCharges: 1,
      elementId: 'water',
    ),
  ];

  @override
  void initState() {
    super.initState();
    playerNameInRun = widget.playerName.trim().isEmpty
        ? '???'
        : widget.playerName.trim();
    lockPhoneLandscapeForDungeon();
    playerMaxHp = max(30, widget.playerMaxHp);
    playerHp = playerMaxHp;
    for (final element in _elements) {
      elementalResist[element.id] = 0;
    }
    for (final art in _allArts) {
      if (art.unlockedByDefault) {
        unlockedArtIds.add(art.effectId);
      }
    }
    for (final weapon in _starterWeapons) {
      if (weapon.unlockedByDefault) {
        unlockedWeaponIds.add(weapon.id);
      }
    }

    for (final costume in _runCostumes) {
      if (costume.unlockedByDefault) {
        unlockedCostumeIds.add(costume.id);
      }
    }

    _loadPermanentProgress();
  }

  bool get _isPhonePlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void lockPhoneLandscapeForDungeon() {
    if (!_isPhonePlatform) return;
    // Keep phone orientation free on mobile to avoid sudden rotation when opening minigames.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void restorePhonePortraitAfterDungeon() {
    if (!_isPhonePlatform) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _skinCodexScrollController.dispose();
    restorePhonePortraitAfterDungeon();
    super.dispose();
  }

  Future<void> _loadPermanentProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final savedArts =
        prefs.getStringList('oculumDungeon.unlockedArtIds') ?? const [];
    final savedWeapons =
        prefs.getStringList('oculumDungeon.unlockedWeaponIds') ?? const [];
    final savedCostumes =
        prefs.getStringList('oculumDungeon.unlockedCostumeIds') ?? const [];
    final savedNpcs =
        prefs.getStringList('oculumDungeon.unlockedNpcIds') ?? const [];
    final savedRelics =
        prefs.getStringList('oculumDungeon.unlockedRelicIds') ?? const [];
    final savedTitles =
        prefs.getStringList('oculumDungeon.unlockedTitleIds') ?? const [];
    final savedEquippedTitles =
        prefs.getStringList('oculumDungeon.equippedTitleIds') ?? const [];
    final savedThemes =
        prefs.getStringList('oculumDungeon.unlockedThemePresetIds') ?? const [];
    final savedTitleLevels = prefs.getString('oculumDungeon.titleLevels');
    final savedAchievements =
        prefs.getStringList('oculumDungeon.completedAchievementIds') ??
        const [];
    final savedSkins =
        prefs.getStringList('oculumDungeon.unlockedSkinIds') ?? const [];
    final savedSkinKills = prefs.getString('oculumDungeon.skinKillCounts');
    final savedSelectedSkin = prefs.getString('oculumDungeon.selectedSkinId');
    final savedSelectedAllies = prefs.getStringList(
      'oculumDungeon.selectedAllyIds',
    );
    final savedActiveAllies =
        prefs.getStringList('oculumDungeon.activeAllyIds') ?? const [];
    final selectedAlliesToLoad = savedSelectedAllies ?? savedActiveAllies;

    if (!mounted) return;

    setState(() {
      unlockedArtIds.addAll(savedArts);
      unlockedArtIds.remove('thousand_fires_emblem_art');
      unlockedWeaponIds.addAll(savedWeapons);
      unlockedCostumeIds.addAll(savedCostumes);
      unlockedNpcIds.addAll(savedNpcs);
      unlockedRelicIds.addAll(savedRelics);
      unlockedTitleIds.addAll(savedTitles);
      equippedTitleIds.addAll(savedEquippedTitles);
      unlockedThemePresetIds.addAll(savedThemes);
      completedAchievementIds.addAll(savedAchievements);
      unlockedSkinIds.addAll(savedSkins);
      if (savedSkinKills != null && savedSkinKills.isNotEmpty) {
        for (final pair in savedSkinKills.split('|')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            skinKillCounts[parts[0]] = int.tryParse(parts[1]) ?? 0;
          }
        }
      }
      if (savedSelectedSkin != null &&
          generateDungeonSkins().any((skin) => skin.id == savedSelectedSkin) &&
          unlockedSkinIds.contains(savedSelectedSkin)) {
        selectedSkinId = savedSelectedSkin;
      }
      selectedAllyIds
        ..clear()
        ..addAll(selectedAlliesToLoad.take(maxActiveAllies));

      oculumSpento = prefs.getInt('oculumDungeon.oculumSpento') ?? oculumSpento;
      runCount = prefs.getInt('oculumDungeon.runCount') ?? runCount;
      gufusUsedInPreviousRun =
          prefs.getBool('oculumDungeon.gufusUsedInPreviousRun') ??
          gufusUsedInPreviousRun;
      posteaGufusEventCompleted =
          prefs.getBool('oculumDungeon.posteaGufusEventCompleted') ??
          posteaGufusEventCompleted;
      if (completedAchievementIds.contains('postea_gufus_rescue')) {
        posteaGufusEventCompleted = true;
        unlockedWeaponIds.add('postea_auto_rifle');
        unlockedWeaponIds.add('postea_grenades');
        unlockedCostumeIds.add('postea_elite_armor');
        unlockedNpcIds.add('postea_elite_guard');
      }
      valleySacrificedInPostea =
          prefs.getBool('oculumDungeon.valleySacrificedInPostea') ??
          valleySacrificedInPostea;
      if (valleySacrificedInPostea) {
        unlockedNpcIds.remove('valley_child_of_mother_nature');
        selectedAllyIds.remove('valley_child_of_mother_nature');
      }
      alliesRecruitedTotal =
          prefs.getInt('oculumDungeon.alliesRecruitedTotal') ??
          alliesRecruitedTotal;

      if (savedTitleLevels != null && savedTitleLevels.isNotEmpty) {
        final pairs = savedTitleLevels.split('|');
        for (final pair in pairs) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            titleLevels[parts[0]] = int.tryParse(parts[1]) ?? 1;
          }
        }
      }

      activeAllies
        ..clear()
        ..addAll(_goodNpcs.where((npc) => selectedAllyIds.contains(npc.id)));

      for (final npc in activeAllies.where(isSmallNpc)) {
        prepareSmallNpcActions(npc);
      }
    });

    addLog(t('Progressi permanenti caricati.', 'Permanent progress loaded.'));

    await tryLoadRunCheckpoint(prefs);
    notifyLoadedThemeUnlocks();
  }

  Future<void> _savePermanentProgress() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'oculumDungeon.unlockedArtIds',
      (unlockedArtIds.where((id) => !isLateGameOnlyArtId(id)).toList()..sort()),
    );
    await prefs.setStringList(
      'oculumDungeon.unlockedWeaponIds',
      unlockedWeaponIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.unlockedCostumeIds',
      unlockedCostumeIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.unlockedNpcIds',
      unlockedNpcIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.unlockedRelicIds',
      unlockedRelicIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.unlockedTitleIds',
      unlockedTitleIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.equippedTitleIds',
      equippedTitleIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.unlockedThemePresetIds',
      unlockedThemePresetIds.toList()..sort(),
    );
    await prefs.setString(
      'oculumDungeon.titleLevels',
      titleLevels.entries.map((e) => '${e.key}:${e.value}').join('|'),
    );
    await prefs.setStringList(
      'oculumDungeon.completedAchievementIds',
      completedAchievementIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.unlockedSkinIds',
      unlockedSkinIds.toList()..sort(),
    );
    await prefs.setString(
      'oculumDungeon.skinKillCounts',
      skinKillCounts.entries.map((e) => '${e.key}:${e.value}').join('|'),
    );
    await prefs.setString('oculumDungeon.selectedSkinId', selectedSkinId);
    await prefs.setStringList(
      'oculumDungeon.activeAllyIds',
      selectedAllyIds.toList()..sort(),
    );
    await prefs.setStringList(
      'oculumDungeon.selectedAllyIds',
      selectedAllyIds.toList()..sort(),
    );

    await prefs.setInt('oculumDungeon.oculumSpento', oculumSpento);
    await prefs.setInt('oculumDungeon.runCount', runCount);
    await prefs.setBool(
      'oculumDungeon.gufusUsedInPreviousRun',
      gufusUsedInPreviousRun,
    );
    await prefs.setBool(
      'oculumDungeon.posteaGufusEventCompleted',
      posteaGufusEventCompleted,
    );
    await prefs.setBool(
      'oculumDungeon.valleySacrificedInPostea',
      valleySacrificedInPostea,
    );
    await prefs.setInt(
      'oculumDungeon.alliesRecruitedTotal',
      alliesRecruitedTotal,
    );
  }

  List<String> get permanentSaveKeys => const [
    'oculumDungeon.unlockedArtIds',
    'oculumDungeon.unlockedWeaponIds',
    'oculumDungeon.unlockedCostumeIds',
    'oculumDungeon.unlockedNpcIds',
    'oculumDungeon.unlockedRelicIds',
    'oculumDungeon.unlockedTitleIds',
    'oculumDungeon.equippedTitleIds',
    'oculumDungeon.unlockedThemePresetIds',
    'oculumDungeon.titleLevels',
    'oculumDungeon.completedAchievementIds',
    'oculumDungeon.unlockedSkinIds',
    'oculumDungeon.skinKillCounts',
    'oculumDungeon.selectedSkinId',
    'oculumDungeon.activeAllyIds',
    'oculumDungeon.selectedAllyIds',
    'oculumDungeon.oculumSpento',
    'oculumDungeon.runCount',
    'oculumDungeon.gufusUsedInPreviousRun',
    'oculumDungeon.posteaGufusEventCompleted',
    'oculumDungeon.valleySacrificedInPostea',
    'oculumDungeon.alliesRecruitedTotal',
  ];

  void showDeleteSaveConfirm() {
    setState(() {
      clearChoices(mode: 'event');

      textIt =
          'Sei sicuro?\n\n'
          'L’occhio si dimenticherà di te, ma sarai comunque qui bloccato.\n\n'
          'Questa scelta cancella progressi permanenti del minigioco: Art, armi, reliquie, Titoli, achievement, Oculum Spento, NPC e contatori run.';
      textEn =
          'Are you sure?\n\n'
          'The eye will forget you, but you will still be trapped here.\n\n'
          'This deletes permanent minigame progress: Arts, weapons, relics, Titles, achievements, Spent Oculum, NPCs and run counters.';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Sì, cancella il save',
          labelEn: 'Yes, delete save',
          icon: Icons.delete_forever,
          color: Colors.redAccent,
          onPressed: deletePermanentSave,
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'No, resta ricordato',
          labelEn: 'No, stay remembered',
          icon: Icons.visibility,
          color: widget.tertiaryColor,
          onPressed: () {
            setState(() {
              clearChoices();
              textIt = 'L’occhio continua a ricordarti.';
              textEn = 'The eye keeps remembering you.';
            });
          },
        ),
      );
    });
  }

  Future<void> deletePermanentSave() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in permanentSaveKeys) {
      await prefs.remove(key);
    }

    if (!mounted) return;

    setState(() {
      clearChoices();

      runActive = false;
      inCombat = false;
      gameOver = false;
      tutorialRunActive = false;

      unlockedArtIds.clear();
      unlockedWeaponIds.clear();
      unlockedNpcIds.clear();
      selectedAllyIds.clear();
      unlockedRelicIds.clear();
      unlockedTitleIds.clear();
      equippedTitleIds.clear();
      unlockedThemePresetIds.clear();
      completedAchievementIds.clear();
      activeAllies.clear();
      clearPosteaEliteGuardState();
      smallNpcActions.clear();
      titleLevels.clear();

      unlockedTitleIds.add('principiante');
      unlockedTitleIds.addAll({
        'starter_occhio_pulito',
        'starter_tasca_di_obser',
        'starter_palpebra_morbida',
      });
      equippedTitleIds.add('principiante');
      titleLevels['principiante'] = 1;

      oculumSpento = 0;
      runCount = 0;
      gufusUsedInPreviousRun = false;
      gufusUsedThisRun = false;
      posteaGufusEventCompleted = false;
      posteaGufusEventActive = false;
      posteaGufusEventPhase = '';
      posteaScientistTurnCounter = 0;
      posteaScientistEnhanced = false;
      valleySacrificedInPostea = false;
      alliesRecruitedTotal = 0;

      starterWeapon = null;
      activeCostume = null;
      activeArt = null;
      activeRelic = null;

      room = 0;
      maxRooms = 0;
      dungeonFloor = 0;
      dungeonLevel = 0;
      dungeonExp = 0;
      currentFloorStart = 1;

      playerHp = playerMaxHp;
      playerShield = 0;
      playerOculumShield = 0;
      playerOculumShieldMax = 0;
      dungeonKarma = 0;
      oculumCharges = 0;
      oculumMaxCharges = 1;

      enemyParty.clear();
      defeatedEnemyNamesIt.clear();
      defeatedEnemyNamesEn.clear();
      defeatedEnemyPowerTotal = 0;
      defeatedEnemyExpTotal = 0;
      defeatedBossCount = 0;
      defeatedEliteCount = 0;
      valleyEncounterSeenThisRun = false;
      valleyTrainingUsedThisRun = false;
      valleyTrainingActive = false;
      valleyTrainingRewardClaimed = false;
      valleyParticipatedInFight = false;
      valleyBloomResolvedThisFight = false;
      valleyTurnsLeft = 0;
      valleyHp = 0;
      valleyMaxHp = 0;
      valleyAttack = 0;
      valleyDefense = 0;
      valleyBloomGuards = 0;
      valleyTrainingTurnsLeft = 0;
      syncPrimaryEnemyFromParty();

      textIt =
          'Save cancellato.\n\n'
          'L’occhio si è dimenticato di te.\n'
          'Eppure sei ancora qui, bloccato, davanti alla palpebra chiusa.';
      textEn =
          'Save deleted.\n\n'
          'The eye has forgotten you.\n'
          'And yet you are still here, trapped before the closed eyelid.';

      addLog(t('Save permanente cancellato.', 'Permanent save deleted.'));
    });
  }

  int? windows1252Byte(int codePoint) {
    if (codePoint <= 0xFF) return codePoint;

    const mapped = {
      0x20AC: 0x80,
      0x201A: 0x82,
      0x0192: 0x83,
      0x201E: 0x84,
      0x2026: 0x85,
      0x2020: 0x86,
      0x2021: 0x87,
      0x02C6: 0x88,
      0x2030: 0x89,
      0x0160: 0x8A,
      0x2039: 0x8B,
      0x0152: 0x8C,
      0x017D: 0x8E,
      0x2018: 0x91,
      0x2019: 0x92,
      0x201C: 0x93,
      0x201D: 0x94,
      0x2022: 0x95,
      0x2013: 0x96,
      0x2014: 0x97,
      0x02DC: 0x98,
      0x2122: 0x99,
      0x0161: 0x9A,
      0x203A: 0x9B,
      0x0153: 0x9C,
      0x017E: 0x9E,
      0x0178: 0x9F,
    };

    return mapped[codePoint];
  }

  String decodeMojibakePass(String value) {
    final bytes = <int>[];

    for (final codePoint in value.runes) {
      final byte = windows1252Byte(codePoint);
      if (byte == null) return value;
      bytes.add(byte);
    }

    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      return value;
    }
  }

  String cleanDungeonText(String value) {
    var cleaned = value;
    for (var i = 0; i < 3; i++) {
      final decoded = decodeMojibakePass(cleaned);
      if (decoded == cleaned) break;
      cleaned = decoded;
    }

    return cleaned.replaceAll('\u00A0', ' ');
  }

  String t(String it, String en) =>
      cleanDungeonText(widget.linguaInglese ? en : it);

  List<_TitleDef> _generateTitles() {
    return const [
      _TitleDef(
        id: 'principiante',
        nameIt: 'Principiante',
        nameEn: 'Beginner',
        descIt:
            'Un occhio appena aperto nel buio. Non sa ancora leggere il Fato, ma sa sopravvivere: cresce piano dopo piano fino a ricordare il nome Esperto di Oculum.',
        descEn:
            'An eye barely opened in the dark. It cannot read Fate yet, but it can survive: it grows floor by floor until it remembers the name Oculum Expert.',
        blindSpotIt:
            'Punto Cieco: gli eventi non ti vedono come un eroe, ma come materiale grezzo. Scudo e armatura ottenuti dagli eventi sono dimezzati.',
        blindSpotEn:
            'Blind Spot: events do not see you as a hero, but as raw material. Shield and armor gained from events are halved.',
        res: 3,
        vol: 0,
        mat: 0,
        ocu: 0,
        damage: 2,
        defense: 0,
      ),
      _TitleDef(
        id: 'campione_primo_villaggio',
        nameIt: 'Campione del Primo Villaggio',
        nameEn: 'Champion of the First Village',
        descIt:
            'Titolo dei villaggi di mostri. Le lotte clandestine non possono più ucciderti, la forza cresce e il corpo ricorda le Martial Art.',
        descEn:
            'Monster village title. Clandestine fights can no longer kill you, strength grows and the body remembers Martial Arts.',
        blindSpotIt:
            'Punto Cieco: i villaggi pretendono spettacolo. Le lotte clandestine attirano più sfidanti.',
        blindSpotEn:
            'Blind Spot: villages demand spectacle. Clandestine fights attract more challengers.',
        res: 1,
        vol: 4,
        mat: 1,
        ocu: 0,
        damage: 8,
        defense: 2,
        strong: true,
      ),
      _TitleDef(
        id: 'slime_skin',
        nameIt: 'Slime Skin',
        nameEn: 'Slime Skin',
        descIt:
            'Titolo Item. Ottenimento: uccisione Slime. Con 20 Slime Skin, chi da l ultimo colpo contro uno Slime tira molto difficile invece di impossibile. Evoluzione: Pelle Reale Slime, richiede Grado I.',
        descEn:
            'Item Title. Obtained by killing Slimes. With 20 Slime Skins, the final blow against a Slime becomes very hard instead of impossible. Evolution: Royal Slime Skin, requires Grade I.',
        blindSpotIt: 'Punto Cieco: subisci x3 danni da fuoco.',
        blindSpotEn: 'Blind Spot: you take x3 fire damage.',
        res: 2,
        vol: 0,
        mat: 0,
        ocu: 0,
        damage: 0,
        defense: 0,
      ),
      _TitleDef(
        id: 'prima_o_poi_tornera',
        nameIt: 'Prima o poi Tornerà',
        nameEn: 'Sooner or Later It Will Return',
        descIt:
            'Titolo del Fato. Ottenimento: uccisione Incubo senza Risveglio infante. Buff narrativo: ottieni un ulteriore bonus ai danni e alla difesa pari a 1/4 della tua difesa. Evoluzione: Ritorno dell Incubo, richiede Grado III.',
        descEn:
            'Fate Title. Obtained by killing the Infant Nightmare Without Awakening. Narrative buff: gain extra damage and defense equal to 1/4 of your defense. Evolution: Nightmare Return, requires Grade III.',
        blindSpotIt: 'Punto Cieco: scrutera nel tuo Fato.',
        blindSpotEn: 'Blind Spot: it will peer into your Fate.',
        res: 0,
        vol: 1,
        mat: 0,
        ocu: 2,
        damage: 2,
        defense: 2,
        strong: true,
      ),
      _TitleDef(
        id: 'uccisore_vero_incubo',
        nameIt: 'Uccisore di un Vero Incubo senza Risveglio',
        nameEn: 'Slayer of a True Nightmare Without Awakening',
        descIt:
            'Titolo del Fato assicurato se uccidi l Incubo di Grado V o maggiore. Buff: ulteriore danno pari a metà livello. Leggenda: chi lo possiede può apprendere abilità del mostro o evocarne parti. Evoluzione: Araldo del Vero Incubo, richiede Grado VII.',
        descEn:
            'Fate Title guaranteed by killing the Nightmare at Grade V or higher. Buff: extra damage equal to half level. Legend: the bearer may learn the monster skills or summon parts of it. Evolution: True Nightmare Herald, requires Grade VII.',
        blindSpotIt:
            'Punto Cieco: non può essere usato insieme alla Maledizione dell Incubo senza Risveglio.',
        blindSpotEn:
            'Blind Spot: cannot be used together with the Nightmare Without Awakening Curse.',
        res: 1,
        vol: 2,
        mat: 0,
        ocu: 2,
        damage: 6,
        defense: 0,
        strong: true,
      ),
      _TitleDef(
        id: 'possessore_occhio_terra',
        nameIt: 'Possessore dell Occhio della Terra',
        nameEn: 'Bearer of the Eye of Earth',
        descIt:
            'Titolo Item. Ottenimento: uccisione Rock Rhino. Buff: +1 Volontà, che diventa +6 contro mostri di roccia, fango e terra. Evoluzione: Corno Tettonico, richiede 9 uccisioni roccia/fango/terra, 3 per tipo.',
        descEn:
            'Item Title. Obtained by killing Rock Rhino. Buff: +1 Will, becoming +6 against rock, mud and earth monsters. Evolution: Tectonic Horn, requires 9 rock/mud/earth kills, 3 of each.',
        blindSpotIt:
            'Punto Cieco: i mostri d acqua hanno +1 Volontà contro di te.',
        blindSpotEn: 'Blind Spot: water monsters have +1 Will against you.',
        res: 0,
        vol: 1,
        mat: 1,
        ocu: 0,
        damage: 0,
        defense: 2,
      ),
      _TitleDef(
        id: 're_slime',
        nameIt: 'Re Slime',
        nameEn: 'Slime King',
        descIt:
            'Titolo Item. Ottenimento: uccisione Re Slime. Buff: +2 Materia, +4 contro Slime. Puoi tentare di trasformare Slime feriti in pet con tiro impossibile: massimo due, uno con spada e uno con staffa. Evoluzione: Corona Gelatinosa, richiede uccidere 30 Slime o risparmiarne 30.',
        descEn:
            'Item Title. Obtained by killing the Slime King. Buff: +2 Materia, +4 against Slimes. You may try to turn wounded Slimes into pets with an impossible roll: max two, one with sword and one with staff. Evolution: Gelatin Crown, requires killing 30 Slimes or sparing 30.',
        blindSpotIt:
            'Punto Cieco: sei infiammabile, prendi il doppio dei danni da fuoco e Ustione dura un azione in più.',
        blindSpotEn:
            'Blind Spot: you are flammable, take double fire damage and Burn lasts one extra action.',
        res: 0,
        vol: 0,
        mat: 2,
        ocu: 1,
        damage: 1,
        defense: 1,
        strong: true,
      ),
      _TitleDef(
        id: 'shadow_mimic_item',
        nameIt: 'Oggetto Casuale del Mimic Ombra',
        nameEn: 'Shadow Mimic Random Item',
        descIt:
            'Titolo Item. Ottenimento: uccisione Shadow Mimic. Buff: +3 a una stat decisa dal Fato. Evoluzione: Baule d Ombra Consapevole, richiede aprire tre forzieri maledetti senza morire.',
        descEn:
            'Item Title. Obtained by killing Shadow Mimic. Buff: +3 to a stat chosen by Fate. Evolution: Aware Shadow Chest, requires opening three cursed chests without dying.',
        blindSpotIt:
            'Punto Cieco: -1 a qualcosa e una conseguenza in roleplay.',
        blindSpotEn:
            'Blind Spot: -1 to something and one roleplay consequence.',
        res: 1,
        vol: 1,
        mat: 1,
        ocu: 1,
        damage: 1,
        defense: 1,
      ),
      _TitleDef(
        id: 'pala_patalpa_dolce',
        nameIt: 'Pala del Patalpa Dolce',
        nameEn: 'Sweet Patalpa Shovel',
        descIt:
            'Titolo Item. Ottenimento: critico contro Patalpa Dolce. Buff: +4 VC e puoi usare Palata. Palata: se critta applica Stun x critico e +2 danni x livello; cooldown narrativo 5 turni. Leggenda: i Patalpa Dolci sono talpe-patata prelibate quanto malvagie, uccidono giovani avventurieri in massa per diventare più grossi, e la pala cresce con la loro stazza.',
        descEn:
            'Item Title. Obtained by landing a critical against Sweet Patalpa. Buff: +4 VC and you may use Shovel Slam. Shovel Slam: on critical applies Stun x critical and +2 damage x level; narrative cooldown 5 turns. Legend: Sweet Patalpas are potato-moles as delicious as they are wicked, killing young adventurers in masses to grow larger, while their shovel grows with their size.',
        blindSpotIt: 'Punto Cieco: -2 percezione.',
        blindSpotEn: 'Blind Spot: -2 perception.',
        res: 0,
        vol: 4,
        mat: 1,
        ocu: 0,
        damage: 4,
        defense: 0,
        strong: true,
      ),
      _TitleDef(
        id: 'radice_gentile',
        nameIt: 'Radice Gentile',
        nameEn: 'Gentle Root',
        descIt:
            'Una radice ti cresce sotto la pelle e ti tiene insieme quando il dungeon prova a spezzarti. Piccola, verde, testarda: cura poco, ma non molla mai.',
        descEn:
            'A root grows under your skin and holds you together when the dungeon tries to break you. Small, green, stubborn: it heals little, but never lets go.',
        blindSpotIt:
            'Punto Cieco: ciò che brucia trova subito la linfa. Il fuoco ti sembra più personale.',
        blindSpotEn:
            'Blind Spot: burning things find the sap first. Fire feels more personal.',
        res: 2,
        vol: 0,
        mat: 1,
        ocu: 0,
        damage: 0,
        defense: 1,
      ),
      _TitleDef(
        id: 'luna_infranta',
        nameIt: 'Luna Infranta',
        nameEn: 'Broken Moon',
        descIt:
            'Porti una scheggia di luna nell’occhio. Non illumina davvero: taglia l’oscurità in pezzi più piccoli e ti lascia respirare tra un frammento e l’altro.',
        descEn:
            'You carry a shard of moon inside your eye. It does not truly shine: it cuts darkness into smaller pieces and lets you breathe between fragments.',
        blindSpotIt:
            'Punto Cieco: la luce crudele non ti purifica, ti espone. Quando qualcosa ti giudica, fa più male.',
        blindSpotEn:
            'Blind Spot: cruel light does not cleanse you, it exposes you. When something judges you, it hurts more.',
        res: 0,
        vol: 0,
        mat: 0,
        ocu: 2,
        damage: 0,
        defense: 1,
      ),
      _TitleDef(
        id: 'stella_nascosta',
        nameIt: 'Stella Nascosta',
        nameEn: 'Hidden Star',
        descIt:
            'Una stella minuscola si nasconde dietro la pupilla e aspetta il momento sbagliato per brillare. I critici sembrano coincidenze, ma il Fato sorride storto.',
        descEn:
            'A tiny star hides behind the pupil and waits for the wrong moment to shine. Critical hits look like coincidence, but Fate smiles crookedly.',
        blindSpotIt:
            'Punto Cieco: il caso ti riconosce e chiede pedaggio. Gli eventi casuali possono costare di più.',
        blindSpotEn:
            'Blind Spot: chance recognizes you and asks for toll. Random events may cost more.',
        res: 0,
        vol: 0,
        mat: 0,
        ocu: 1,
        damage: 1,
        defense: 0,
      ),
      _TitleDef(
        id: 'pelle_di_muschio',
        nameIt: 'Pelle di Muschio',
        nameEn: 'Moss Skin',
        descIt:
            'Il corpo impara a farsi bosco. Ogni ferita trova muschio, ogni passo lascia una traccia morbida, ogni stanza ti ricuce un poco.',
        descEn:
            'The body learns to become a forest. Every wound finds moss, every step leaves a soft trace, every room stitches you a little.',
        blindSpotIt:
            'Punto Cieco: sei più vivo, ma meno leggero. La schivata perde grazia.',
        blindSpotEn:
            'Blind Spot: you are more alive, but less light. Dodging loses grace.',
        res: 1,
        vol: 0,
        mat: 2,
        ocu: 0,
        damage: 0,
        defense: 2,
      ),
      _TitleDef(
        id: 'corona_di_sale',
        nameIt: 'Corona di Sale',
        nameEn: 'Salt Crown',
        descIt:
            'Una corona ruvida, fatta di sale e orgoglio, brucia sopra la fronte. Ti rende più duro, più affamato, più disposto a colpire prima di piangere.',
        descEn:
            'A rough crown made of salt and pride burns above your brow. It makes you harder, hungrier, more willing to strike before crying.',
        blindSpotIt:
            'Punto Cieco: il sale conserva anche il dolore. Le cure sembrano meno dolci.',
        blindSpotEn:
            'Blind Spot: salt preserves pain too. Healing feels less sweet.',
        res: 0,
        vol: 2,
        mat: 0,
        ocu: 0,
        damage: 2,
        defense: 0,
        strong: true,
      ),
      _TitleDef(
        id: 'occhio_del_nido',
        nameIt: 'Occhio del Nido',
        nameEn: 'Nest Eye',
        descIt:
            'Non è un occhio solo: è un nido che guarda. Ogni stat cresce di poco, come se piccole creature dentro di te spingessero nella stessa direzione.',
        descEn:
            'It is not a single eye: it is a nest that watches. Every stat grows a little, as if tiny creatures inside you push in the same direction.',
        blindSpotIt:
            'Punto Cieco: i boss sentono il nido muoversi. Le cose grandi ti notano prima.',
        blindSpotEn:
            'Blind Spot: bosses hear the nest moving. Large things notice you sooner.',
        res: 1,
        vol: 1,
        mat: 1,
        ocu: 1,
        damage: 1,
        defense: 1,
        strong: true,
      ),
      _TitleDef(
        id: 'fiato_di_cenere',
        nameIt: 'Fiato di Cenere',
        nameEn: 'Ash Breath',
        descIt:
            'Respiri come dopo un incendio. Ogni colpo porta una polvere calda, ogni parola sa di brace spenta che potrebbe tornare viva.',
        descEn:
            'You breathe like after a fire. Every strike carries warm dust, every word tastes like dead ember that could wake again.',
        blindSpotIt:
            'Punto Cieco: l’acqua non ti calma, ti spegne. Gli elementi freddi o liquidi diventano più minacciosi.',
        blindSpotEn:
            'Blind Spot: water does not calm you, it extinguishes you. Cold or liquid elements become more threatening.',
        res: 0,
        vol: 1,
        mat: 0,
        ocu: 0,
        damage: 3,
        defense: 0,
      ),
      _TitleDef(
        id: 'mano_del_pozzo',
        nameIt: 'Mano del Pozzo',
        nameEn: 'Well Hand',
        descIt:
            'Una mano bagnata ti tira verso il basso, ma non per ucciderti: vuole insegnarti il peso. La Materia risponde meglio quando smetti di respirare forte.',
        descEn:
            'A wet hand pulls you downward, but not to kill you: it wants to teach you weight. Materia answers better when you stop breathing loudly.',
        blindSpotIt:
            'Punto Cieco: i pozzi ricordano i debiti. Gli eventi maledetti possono chiedere più Obser.',
        blindSpotEn:
            'Blind Spot: wells remember debts. Cursed events may ask for more Obser.',
        res: 0,
        vol: 0,
        mat: 3,
        ocu: 0,
        damage: 0,
        defense: 1,
      ),
      _TitleDef(
        id: 'eco_del_fiore',
        nameIt: 'Eco del Fiore',
        nameEn: 'Flower Echo',
        descIt:
            'Un fiore senza bocca ripete il tuo dolore in una lingua vegetale. Non ti salva subito, ma rende ogni stanza un poco meno definitiva.',
        descEn:
            'A mouthless flower repeats your pain in a vegetal tongue. It does not save you at once, but makes every room a little less final.',
        blindSpotIt:
            'Punto Cieco: ciò che è velenoso ti ascolta meglio. I veleni insistono più a lungo.',
        blindSpotEn:
            'Blind Spot: poisonous things listen to you better. Venoms linger longer.',
        res: 0,
        vol: 0,
        mat: 0,
        ocu: 2,
        damage: 0,
        defense: 0,
      ),
      _TitleDef(
        id: 'dente_di_stella',
        nameIt: 'Dente di Stella',
        nameEn: 'Star Tooth',
        descIt:
            'Una stella ti ha lasciato un dente nella carne. Morde quando attacchi, ride quando fai critico, e non si preoccupa di difenderti.',
        descEn:
            'A star left a tooth inside your flesh. It bites when you attack, laughs when you crit, and does not care about defending you.',
        blindSpotIt:
            'Punto Cieco: brillare ti rende fragile. La difesa ottenuta dagli eventi può essere dimezzata.',
        blindSpotEn:
            'Blind Spot: shining makes you fragile. Defense gained from events may be halved.',
        res: 0,
        vol: 2,
        mat: 0,
        ocu: 1,
        damage: 4,
        defense: -1,
        strong: true,
      ),
      _TitleDef(
        id: 'ombra_che_ascolta',
        nameIt: 'Ombra che Ascolta',
        nameEn: 'Listening Shadow',
        descIt:
            'La tua ombra non ti segue: ti ascolta. Quando colpisci, beve una parte del male e te la restituisce come respiro.',
        descEn:
            'Your shadow does not follow you: it listens. When you strike, it drinks part of the harm and gives it back as breath.',
        blindSpotIt:
            'Punto Cieco: la luce dei santuari non ti benedice volentieri. Gli eventi sacri possono diventare più severi.',
        blindSpotEn:
            'Blind Spot: shrine light does not bless you gladly. Sacred events may become stricter.',
        res: 0,
        vol: 2,
        mat: 0,
        ocu: 1,
        damage: 1,
        defense: 0,
      ),

      _TitleDef(
        id: 'mille_lacrime',
        nameIt: 'Mille Lacrime Piccole',
        nameEn: 'Thousand Small Tears',
        descIt:
            'Non piangi una volta: piangi in mille occhi minuscoli. Ogni lacrima è debole, ma insieme diventano una pioggia che confonde il dungeon.',
        descEn:
            'You do not cry once: you cry through a thousand tiny eyes. Each tear is weak, but together they become rain that confuses the dungeon.',
        blindSpotIt:
            'Punto Cieco: a volte il pianto chiama qualcuno. Al piano 6 può apparire qualcosa che non sa se consolarti o giudicarti.',
        blindSpotEn:
            'Blind Spot: sometimes crying calls someone. On floor 6, something may appear that does not know whether to comfort or judge you.',
        res: 1,
        vol: 0,
        mat: 1,
        ocu: 2,
        damage: 0,
        defense: 2,
        strong: true,
      ),
      _TitleDef(
        id: 'osso_che_prega',
        nameIt: 'Osso che Prega',
        nameEn: 'Praying Bone',
        descIt:
            'Un osso dentro di te ha imparato a pregare al posto tuo. Non chiede salvezza: chiede di reggere un altro colpo.',
        descEn:
            'A bone inside you learned to pray in your place. It does not ask for salvation: it asks to endure one more hit.',
        blindSpotIt:
            'Punto Cieco: i core di corruzione sentono la preghiera e rispondono. Potrebbero chiamarti più spesso.',
        blindSpotEn:
            'Blind Spot: corruption cores hear the prayer and answer. They may call you more often.',
        res: 1,
        vol: 0,
        mat: 1,
        ocu: 0,
        damage: 0,
        defense: 4,
        strong: true,
      ),
      _TitleDef(
        id: 'coro_sottopelle',
        nameIt: 'Coro Sottopelle',
        nameEn: 'Under-Skin Choir',
        descIt:
            'Sotto la pelle cantano voci sottili, tutte leggermente stonate. Quando colpisci bene, il coro urla e il suono diventa lama.',
        descEn:
            'Thin voices sing under your skin, all slightly off-key. When you strike well, the choir screams and sound becomes a blade.',
        blindSpotIt:
            'Punto Cieco: il silenzio ti fa sentire tutti insieme. Gli effetti di silenzio o controllo possono stordirti più facilmente.',
        blindSpotEn:
            'Blind Spot: silence makes you hear them all at once. Silence or control effects may stun you more easily.',
        res: 0,
        vol: 2,
        mat: 0,
        ocu: 1,
        damage: 3,
        defense: -1,
        strong: true,
      ),
      _TitleDef(
        id: 'giardino_nel_torace',
        nameIt: 'Giardino nel Torace',
        nameEn: 'Garden in the Chest',
        descIt:
            'Nel petto cresce un giardino che non ha visto il sole. Ogni stanza gli dà acqua, ogni ferita gli dà terra.',
        descEn:
            'A garden grows in your chest, one that has never seen the sun. Every room gives it water, every wound gives it soil.',
        blindSpotIt:
            'Punto Cieco: cenere e fuoco trovano subito le radici. Le bruciature entrano più in profondità.',
        blindSpotEn:
            'Blind Spot: ash and fire find the roots at once. Burns sink deeper.',
        res: 3,
        vol: 0,
        mat: 1,
        ocu: 0,
        damage: 0,
        defense: 1,
      ),
      _TitleDef(
        id: 'mano_senza_dito',
        nameIt: 'Mano Senza Dito',
        nameEn: 'Fingerless Hand',
        descIt:
            'Una mano incompleta ti stringe il polso quando stai per scegliere male. Non può indicare la via, ma può ancora colpire.',
        descEn:
            'An incomplete hand grips your wrist when you are about to choose wrong. It cannot point the way, but it can still strike.',
        blindSpotIt:
            'Punto Cieco: ogni patto nota la mano mancante. Contratti e scambi possono costare un poco di più.',
        blindSpotEn:
            'Blind Spot: every pact notices the missing hand. Contracts and trades may cost a little more.',
        res: 0,
        vol: 2,
        mat: 0,
        ocu: 0,
        damage: 2,
        defense: 0,
      ),
      _TitleDef(
        id: 'palpebra_di_sale',
        nameIt: 'Palpebra di Sale',
        nameEn: 'Salt Eyelid',
        descIt:
            'Una palpebra salata si chiude sopra l’Oculum quando il mondo diventa troppo chiaro. Non blocca la vista: la rende più crudele.',
        descEn:
            'A salty eyelid closes over the Oculum when the world becomes too clear. It does not block sight: it makes it crueler.',
        blindSpotIt:
            'Punto Cieco: le lacrime rare attirano mantelli pieni d’occhi. Alcuni miniboss potrebbero trovarti prima.',
        blindSpotEn:
            'Blind Spot: rare tears attract mantles full of eyes. Some minibosses may find you sooner.',
        res: 0,
        vol: 0,
        mat: 2,
        ocu: 2,
        damage: 0,
        defense: 2,
        strong: true,
      ),
      _TitleDef(
        id: 'fame_di_stelle',
        nameIt: 'Fame di Stelle',
        nameEn: 'Star Hunger',
        descIt:
            'Hai fame di cose lontane. Ogni danno è un morso verso l’alto, ogni critico una stella che cade troppo vicino.',
        descEn:
            'You hunger for distant things. Every damage is a bite upward, every crit a star falling too close.',
        blindSpotIt:
            'Punto Cieco: chi ha fame non guarisce bene. Gli eventi di cura possono darti meno.',
        blindSpotEn:
            'Blind Spot: the hungry do not heal well. Healing events may give less.',
        res: -1,
        vol: 2,
        mat: 0,
        ocu: 1,
        damage: 5,
        defense: -2,
        strong: true,
      ),
      _TitleDef(
        id: 'nervo_di_luna',
        nameIt: 'Nervo di Luna',
        nameEn: 'Moon Nerve',
        descIt:
            'Un nervo lunare vibra dietro l’occhio. Non ti rende calmo: ti rende preciso quando tremi.',
        descEn:
            'A lunar nerve vibrates behind the eye. It does not make you calm: it makes you precise while shaking.',
        blindSpotIt:
            'Punto Cieco: il Sole riconosce il nervo e lo tira. Gli eventi solari possono giudicarti più duramente.',
        blindSpotEn:
            'Blind Spot: the Sun recognizes the nerve and pulls it. Solar events may judge you harder.',
        res: 0,
        vol: 0,
        mat: 0,
        ocu: 3,
        damage: 0,
        defense: 1,
      ),

      _TitleDef(
        id: 'esperto_di_oculum',
        nameIt: 'Esperto di Oculum',
        nameEn: 'Oculum Expert',
        descIt:
            'Non sei diventato invincibile: sei diventato leggibile dal dungeon. Le tue Open lasciano eco, i tuoi occhi hanno imparato a non chiedere scusa.',
        descEn:
            'You did not become invincible: you became readable to the dungeon. Your Opens leave echoes, your eyes learned not to apologize.',
        blindSpotIt:
            'Punto Cieco: i boss ricordano il tuo nome e non ti trattano più come un passante.',
        blindSpotEn:
            'Blind Spot: bosses remember your name and no longer treat you like a passerby.',
        res: 3,
        vol: 3,
        mat: 3,
        ocu: 3,
        damage: 9,
        defense: 9,
        strong: true,
      ),
      _TitleDef(
        id: 'archivista_dei_piani',
        nameIt: 'Archivista dei Piani',
        nameEn: 'Floor Archivist',
        descIt:
            'Ogni piano ti lascia una pagina sotto la lingua. Gli eventi mostrano più cuciture, più scelte, più modi per sbagliare bene.',
        descEn:
            'Each floor leaves a page under your tongue. Events show more seams, more choices, more ways to fail properly.',
        blindSpotIt:
            'Punto Cieco: le stanze vuote leggono te in cambio. Il silenzio non è mai gratuito.',
        blindSpotEn:
            'Blind Spot: empty rooms read you back. Silence is never free.',
        res: 0,
        vol: 0,
        mat: 2,
        ocu: 2,
        damage: 1,
        defense: 2,
        strong: true,
      ),
      _TitleDef(
        id: 'lama_delle_dodici_palpebre',
        nameIt: 'Lama delle Dodici Palpebre',
        nameEn: 'Blade of Twelve Eyelids',
        descIt:
            'Dodici palpebre si chiudono una dopo l’altra lungo la lama. Quando l’ultima batte, il colpo ha già deciso.',
        descEn:
            'Twelve eyelids close one after another along the blade. When the last one blinks, the strike has already decided.',
        blindSpotIt:
            'Punto Cieco: inizi i boss più scoperto. La lama vuole il primo sangue, non la prudenza.',
        blindSpotEn:
            'Blind Spot: you start bosses more exposed. The blade wants first blood, not caution.',
        res: 0,
        vol: 4,
        mat: 0,
        ocu: 1,
        damage: 12,
        defense: -2,
        strong: true,
      ),
      _TitleDef(
        id: 'cuore_del_core_viola',
        nameIt: 'Cuore del Core Viola',
        nameEn: 'Purple Core Heart',
        descIt:
            'Un core viola batte piano dove non dovrebbe esserci un secondo cuore. Non ti corrompe: ti insegna a contrattare con la corruzione.',
        descEn:
            'A purple core beats softly where a second heart should not be. It does not corrupt you: it teaches you to bargain with corruption.',
        blindSpotIt:
            'Punto Cieco: i core rossi ti odiano perché hai scelto un altro colore.',
        blindSpotEn:
            'Blind Spot: red cores hate you because you chose another color.',
        res: 1,
        vol: 0,
        mat: 2,
        ocu: 4,
        damage: 0,
        defense: 4,
        strong: true,
      ),

      _TitleDef(
        id: 'starter_occhio_pulito',
        nameIt: 'Occhio Pulito',
        nameEn: 'Clean Eye',
        descIt:
            'Titolo starter. Un piccolo occhio ancora non graffiato dal dungeon: ti dà stabilità senza chiederti niente in cambio.',
        descEn:
            'Starter Title. A small eye not yet scratched by the dungeon: it gives stability without asking anything back.',
        blindSpotIt: 'Nessun Punto Cieco.',
        blindSpotEn: 'No Blind Spot.',
        res: 1,
        vol: 1,
        mat: 0,
        ocu: 0,
        damage: 1,
        defense: 0,
      ),
      _TitleDef(
        id: 'starter_tasca_di_obser',
        nameIt: 'Tasca di Obser',
        nameEn: 'Obser Pocket',
        descIt:
            'Titolo starter. Hai imparato a non perdere le piccole pietre con l’occhio inciso. Più utile che eroico.',
        descEn:
            'Starter Title. You learned not to lose the small stones with engraved eyes. More useful than heroic.',
        blindSpotIt: 'Nessun Punto Cieco.',
        blindSpotEn: 'No Blind Spot.',
        res: 0,
        vol: 1,
        mat: 1,
        ocu: 0,
        damage: 0,
        defense: 1,
      ),
      _TitleDef(
        id: 'starter_palpebra_morbida',
        nameIt: 'Palpebra Morbida',
        nameEn: 'Soft Eyelid',
        descIt:
            'Titolo starter. Una protezione piccola, quasi tenera, che si chiude prima che il dungeon ti entri tutto negli occhi.',
        descEn:
            'Starter Title. A small, almost tender protection that closes before the dungeon fully enters your eyes.',
        blindSpotIt: 'Nessun Punto Cieco.',
        blindSpotEn: 'No Blind Spot.',
        res: 1,
        vol: 0,
        mat: 1,
        ocu: 1,
        damage: 0,
        defense: 1,
      ),
    ];
  }

  List<_RelicDef> _generateRelics() {
    final relics = <_RelicDef>[
      const _RelicDef(
        id: 'carillon_fifi',
        nameIt: 'Carillon di Fifi',
        nameEn: 'Fifi Music Box',
        descIt:
            'Open una volta per piano: addormenta gli avversari per 1d6 azioni.',
        descEn: 'Open once per floor: puts enemies to sleep for 1d6 actions.',
        effectId: 'fifi_sleep',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'romanzo_ahrya',
        nameIt: 'Il Romanzo di Ahrya',
        nameEn: 'Ahrya Novel',
        descIt: 'Puoi portare un NPC in più se lo hai incontrato nella storia.',
        descEn: 'You can bring one more NPC if met in the story.',
        effectId: 'ahrya_extra_ally',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'graffi_sonici_hoshy',
        nameIt: 'Graffi Sonici di Hoshy',
        nameEn: 'Hoshy Sonic Scratches',
        descIt:
            'Open una volta per piano: 1d100×2 + danni normali, +20 Scudo per membro del party incluso te.',
        descEn:
            'Open once per floor: 1d100×2 + normal damage, +20 Shield for each party member including you.',
        effectId: 'hoshy_open',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'vermi_decadenti_vervain',
        nameIt: 'Vermi Decadenti di Vervain',
        nameEn: 'Vervain Decaying Worms',
        descIt:
            'Open una volta per piano: immobilizza/divora i nemici e +5 a tutte le stats fino a fine piano.',
        descEn:
            'Open once per floor: immobilizes/devours enemies and +5 to all stats until floor end.',
        effectId: 'vervain_open',
        unlockedByDefault: false,
      ),

      const _RelicDef(
        id: 'starter_leaf_pin',
        nameIt: 'Spilla della Foglia che Torna',
        nameEn: 'Returning Leaf Pin',
        descIt:
            'Starter. La prima volta per piano in cui subisci danno, ottieni +8 Scudo.',
        descEn:
            'Starter. The first time each floor you take damage, gain +8 Shield.',
        effectId: 'starter_leaf_pin',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'starter_kooba_gear',
        nameIt: 'Ingranaggio Buono di Kooba',
        nameEn: 'Kooba Good Gear',
        descIt:
            'Starter. +3 Obser iniziali e piccola chance di trovare un Ingranaggio Scintillante nelle stanze vuote.',
        descEn:
            'Starter. +3 starting Obser and a small chance to find a Glimmering Gear in empty rooms.',
        effectId: 'starter_kooba_gear',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'starter_tiny_vitalium',
        nameIt: 'Scheggia di Vitalium Grezzo',
        nameEn: 'Raw Vitalium Shard',
        descIt: 'Starter. Parti con +1 Vitalium Grezzo e +10 HP massimi.',
        descEn: 'Starter. Start with +1 Raw Vitalium and +10 max HP.',
        effectId: 'starter_tiny_vitalium',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'mani_teschio',
        nameIt: 'Mani del Teschio',
        nameEn: 'Skull Hands',
        descIt:
            'Solo senza Taverniere in squadra. Due mani scheletriche con la tua vita prendono danni al posto tuo.',
        descEn:
            'Only without the Tavernkeeper. Two skeletal hands with your HP take damage for you.',
        effectId: 'skeleton_hands',
        requiresNoTavernkeeper: true,
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'pawn_guardiano',
        nameIt: 'Pawn',
        nameEn: 'Pawn',
        descIt:
            'Guardiano con 120 HP, 20 Volontà, 15 Materia. Prende danni, attacca, schiva con +7 e prende +10 Scudo ogni turno.',
        descEn:
            'Guardian with 120 HP, 20 Will, 15 Materia. Tanks, attacks, dodges at +7 and gains +10 Shield each turn.',
        effectId: 'pawn_guardian',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'seme_rinascita',
        nameIt: 'Seme di Rinascita',
        nameEn: 'Rebirth Seed',
        descIt:
            'Trovabile dal piano 3. Dà Rinascita: se muori, rinasci con vita piena e Oculum triplicato.',
        descEn:
            'Found from floor 3. Grants Rebirth: on death, revive full HP with tripled Oculum.',
        effectId: 'rebirth_seed',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'occhio_baghest',
        nameIt: 'Occhio di Baghest',
        nameEn: 'Baghest Eye',
        descIt:
            'Evita il boss Eiva Baghest e permette di prendere reliquie dai core rossi senza corruzione.',
        descEn:
            'Prevents Eiva Baghest and lets you take relics from red cores without corruption.',
        effectId: 'baghest_eye',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'costume_baghest',
        nameIt: 'Costume da Cultista di Baghest',
        nameEn: 'Baghest Cultist Costume',
        descIt:
            'Le élite non ti attaccano: puoi andartene al 100% o tentare un attacco letale +500%.',
        descEn:
            'Elites do not attack you: flee at 100% or try a lethal +500% attack.',
        effectId: 'baghest_cultist_costume',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'costume_oculiano',
        nameIt: 'Costume da Oculiano',
        nameEn: 'Oculian Costume',
        descIt:
            'Trasforma core rossi in viola, tieni tre Art, Oculum iniziale 2/2 e cure casuali con reazioni.',
        descEn:
            'Turns red cores purple, keeps three Arts, starts Oculum 2/2 and heals randomly with reactions.',
        effectId: 'oculian_costume',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'occhio_scudo_oculum',
        nameIt: 'Occhio dello Scudo Oculum',
        nameEn: 'Oculum Shield Eye',
        descIt:
            'Reliquia di Karma. Parti con 50 Scudo Oculum: ogni Scudo normale diventa Scudo Oculum, ma la vita massima scende del 60%.',
        descEn:
            'Karma Relic. Start with 50 Oculum Shield: every normal Shield becomes Oculum Shield, but max HP drops by 60%.',
        effectId: 'oculum_shield_converter',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'piuma_fredda',
        nameIt: 'Piuma Fredda',
        nameEn: 'Cold Feather',
        descIt: '+2 schivate iniziali e +4 critico. Non è una foglia.',
        descEn: '+2 starting dodges and +4 crit. It is not a leaf.',
        effectId: 'cold_feather',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'lacrima_obser',
        nameIt: 'Lacrima Obser Antica',
        nameEn: 'Ancient Obser Tear',
        descIt: '+12 Obser iniziali e i mercanti costano leggermente meno.',
        descEn: '+12 starting Obser and merchants are slightly cheaper.',
        effectId: 'ancient_obser',
        unlockedByDefault: true,
      ),

      const _RelicDef(
        id: 'nido_di_muschio',
        nameIt: 'Nido di Muschio',
        nameEn: 'Moss Nest',
        descIt:
            'Open: evoca radici che curano e legano. Skill minore sempre usabile.',
        descEn:
            'Open: summons roots that heal and bind. Lesser skill always usable.',
        effectId: 'open_nature_root',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'luna_lattea',
        nameIt: 'Luna Lattea',
        nameEn: 'Milky Moon',
        descIt:
            'Open: cura, scudo e confusione lunare. Skill minore sempre usabile.',
        descEn:
            'Open: healing, shield and lunar confusion. Lesser skill always usable.',
        effectId: 'open_moon_milk',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'stella_spina',
        nameIt: 'Stella Spina',
        nameEn: 'Thorn Star',
        descIt: 'Open: pioggia stellare e debuff. Skill minore sempre usabile.',
        descEn: 'Open: star rain and debuff. Lesser skill always usable.',
        effectId: 'open_star_thorn',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'brace_bambina',
        nameIt: 'Brace Bambina',
        nameEn: 'Child Ember',
        descIt: 'Open: fuoco piccolo ma crudele. Skill minore sempre usabile.',
        descEn: 'Open: small but cruel fire. Lesser skill always usable.',
        effectId: 'open_fire_child',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'vaso_dei_morti_piccoli',
        nameIt: 'Vaso dei Morti Piccoli',
        nameEn: 'Jar of Small Dead',
        descIt: 'Open: evoca tre resti fragili. Skill minore sempre usabile.',
        descEn:
            'Open: summons three fragile remains. Lesser skill always usable.',
        effectId: 'open_summon_small_dead',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'acqua_senza_gola',
        nameIt: 'Acqua Senza Gola',
        nameEn: 'Throatless Water',
        descIt: 'Open: annega la voce del nemico. Skill minore sempre usabile.',
        descEn: 'Open: drowns the enemy voice. Lesser skill always usable.',
        effectId: 'open_water_silence',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'vento_sotto_unghia',
        nameIt: 'Vento Sotto Unghia',
        nameEn: 'Wind Under Nail',
        descIt: 'Open: schivate e tagli rapidi. Skill minore sempre usabile.',
        descEn: 'Open: dodges and fast cuts. Lesser skill always usable.',
        effectId: 'open_wind_nail',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'sale_delle_ossa',
        nameIt: 'Sale delle Ossa',
        nameEn: 'Bone Salt',
        descIt: 'Open: scudo, spine e immobilità. Skill minore sempre usabile.',
        descEn:
            'Open: shield, thorns and immobility. Lesser skill always usable.',
        effectId: 'open_bone_salt',
        unlockedByDefault: false,
      ),
      const _RelicDef(
        id: 'cipo_non_e_solo',
        nameIt: 'Cipo non è solo',
        nameEn: 'Cipo Is Not Alone',
        descIt:
            'Open: evoca un enorme serpente di legno con dentro una luce verde. Ha il doppio della vita del PG, attira i colpi, dà +5 ai tiri e +5 danni. Skill: morso del serpente, fragilità e +5 danni.',
        descEn:
            'Open: summons a huge wooden serpent with green light inside. It has double player HP, draws attacks, grants +5 rolls and +5 damage. Skill: serpent bite, fragility and +5 damage.',
        effectId: 'open_cipo_serpent',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'preghiera_del_soldato',
        nameIt: 'Preghiera del Soldato',
        nameEn: 'Soldier Prayer',
        descIt:
            'Open: mani giganti di energia gialla ti benedicono con 1d20 al prossimo tiro. Skill: +1d6 al prossimo tiro. Buff: +6 a tutte le stats.',
        descEn:
            'Open: giant yellow energy hands bless you with 1d20 on the next roll. Skill: +1d6 on next roll. Buff: +6 to all stats.',
        effectId: 'open_soldier_prayer',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'concentrazione_floreale',
        nameIt: 'Concentrazione Floreale',
        nameEn: 'Floral Focus',
        descIt:
            'Open: la terra fiorisce e rialza 1d6 umani che si uccidono per salvarti, pietrificandosi in pietra durissima.',
        descEn:
            'Open: the earth blooms and raises 1d6 humans who sacrifice themselves to save you, petrifying into hard stone.',
        effectId: 'open_floral_focus',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'danza_tribale',
        nameIt: 'Danza Tribale',
        nameEn: 'Tribal Dance',
        descIt:
            'Open: stile di combattimento in danza, 1d6+2 colpi; dal secondo colpo fanno metà danno. Skill: versione ridotta 1d4 colpi. Buff: Skill +2 colpi e +50 HP temporanei.',
        descEn:
            'Open: fighting dance, 1d6+2 hits; hits after the first deal half damage. Skill: reduced 1d4-hit version. Buff: Skill +2 hits and +50 temporary HP.',
        effectId: 'open_tribal_dance',
        unlockedByDefault: true,
      ),
      const _RelicDef(
        id: 'scudo_dell_io',
        nameIt: "Scudo dell'Io",
        nameEn: 'Shield of the Self',
        descIt:
            'Open: crei uno scudo gigantesco con la tua volontà d’oro, HP pari a CM +10. Skill: +5 danni per fight, stack fino a 5. Buff: la Skill dà anche +2 difesa.',
        descEn:
            'Open: create a giant golden-will shield with HP equal to CM +10. Skill: +5 damage for the fight, stacks up to 5. Buff: the Skill also grants +2 defense.',
        effectId: 'open_ego_shield',
        unlockedByDefault: true,
      ),
    ];

    final elements = _elements
        .map((e) => e.id)
        .where((id) => id != 'neutral')
        .toList();
    for (var i = relics.length + 1; i <= 96; i++) {
      final element = elements[(i - 1) % elements.length];
      relics.add(
        _RelicDef(
          id: 'relic_$i',
          nameIt: 'Reliquia $i — ${elementName(element)}',
          nameEn: 'Relic $i — ${elementName(element)}',
          descIt:
              'Reliquia rara procedurale: +1 ${elementName(element)}, piccola mutazione di run.',
          descEn:
              'Rare procedural relic: +1 ${elementName(element)}, small run mutation.',
          effectId: 'minor_$element',
          unlockedByDefault: false,
        ),
      );
    }

    return relics;
  }

  static final List<_EquipmentSetDef> _equipmentSets = _buildEquipmentSets();

  static List<_EquipmentSetDef> _buildEquipmentSets() {
    const setSeeds = [
      (
        'lama_scudo_oculum',
        "Lama e Scudo dell'Oculum",
        'Oculum Blade and Shield',
        'oculum_blade_shield_set',
        'oculian_eye_armor',
        'Il set della foto: lama impugnata, scudo vivo e armatura oculiana.',
      ),
      (
        'palpebra_incisa',
        'Palpebra Incisa',
        'Engraved Eyelid',
        'eyelid_shield',
        'oculian_eye_mantle',
        'Scudo chiuso e mantello pieno di occhi spenti.',
      ),
      (
        'obser_sepolto',
        'Obser Sepolto',
        'Buried Obser',
        'obser_sword',
        'obser_merchant_jacket',
        'Pietra incisa e tasche da mercante troppo silenziose.',
      ),
      (
        'oculum_cavo',
        'Oculum Cavo',
        'Hollow Oculum',
        'hollow_oculum_staff',
        'ragged_oculum_cloak',
        'Bastone cavo e mantello base cucito male.',
      ),
      (
        'bottoni_osso',
        "Bottoni d'Osso",
        'Bone Buttons',
        'eyelid_shield',
        'bone_button_armor',
        'Armatura e scudo si chiudono come una mandibola.',
      ),
      (
        'baghest_nero',
        'Baghest Nero',
        'Black Baghest',
        'black_mimic_dagger',
        'baghest_cultist_armor',
        'Pugnale mimic e maschera cultista.',
      ),
      (
        'hideano_braci',
        'Hideano delle Braci',
        'Hidean Embers',
        'hidenas_saber',
        'hidenas_thousand_ember_uniform',
        'Lama calda e uniforme che non ammette cenere.',
      ),
      (
        'affogati_marea',
        'Affogati della Marea',
        'Drowned Tide',
        'tidal_needle',
        'drowned_city_robe',
        'Ago bendato e tunica di acqua vecchia.',
      ),
      (
        'vapium_muto',
        'Vapium Muto',
        'Mute Vapium',
        'vapium_hammer',
        'vapium_vapor_plate',
        'Martello e corazza diventano nebbia quando menti.',
      ),
      (
        'lunium_rosa',
        'Lunium Rosa',
        'Rose Lunium',
        'hollow_oculum_staff',
        'moonhills_lunium_veil',
        'Occhi cavi sotto un velo che ricorda al posto tuo.',
      ),
      (
        'evonest_triplo',
        'Evonest Triplo',
        'Triple Evonest',
        'tidal_needle',
        'evonest_triple_shell',
        'Tre respiri marini attorno a una lama sottile.',
      ),
      (
        'asher_contratto',
        'Contratto di Asher',
        'Asher Contract',
        'hidenas_saber',
        'asher_burnt_contract',
        'Il fuoco firma prima di ferire.',
      ),
    ];

    final sets = <_EquipmentSetDef>[];
    sets.addAll([
      _EquipmentSetDef(
        id: 'postea_elite_rifle_set',
        nameIt: 'Set Elite di Postea - Fucile',
        nameEn: 'Postea Elite Set - Rifle',
        descIt:
            'Fucile Automatico di Postea e Armatura Elite Postea. Il futuro chiuso ti copre con protocolli militari.',
        descEn:
            'Postea Automatic Rifle and Postea Elite Armor. The sealed future covers you with military protocols.',
        weaponIds: {'postea_auto_rifle'},
        costumeIds: {'postea_elite_armor'},
        damageBonus: 5,
        defenseBonus: 3,
        shieldBonus: 20,
        critBonus: 5,
        victoryChanceBonus: 6,
      ),
      _EquipmentSetDef(
        id: 'postea_elite_grenade_set',
        nameIt: 'Set Elite di Postea - Granate',
        nameEn: 'Postea Elite Set - Grenades',
        descIt:
            'Granate di Postea e Armatura Elite Postea. L AoE VC non consuma Oculum e lo Scudo Critico resta pronto.',
        descEn:
            'Postea Grenades and Postea Elite Armor. VC AoE costs no Oculum and Critical Shield stays ready.',
        weaponIds: {'postea_grenades'},
        costumeIds: {'postea_elite_armor'},
        damageBonus: 3,
        defenseBonus: 4,
        shieldBonus: 25,
        critBonus: 4,
        victoryChanceBonus: 6,
      ),
    ]);
    for (var i = 0; i < 36; i++) {
      final seed = setSeeds[i % setSeeds.length];
      final tier = i ~/ setSeeds.length;
      final tierNameIt = tier == 0
          ? ''
          : tier == 1
          ? ' II'
          : ' III';
      final tierNameEn = tierNameIt;
      sets.add(
        _EquipmentSetDef(
          id: '${seed.$1}_$tier',
          nameIt: '${seed.$2}$tierNameIt',
          nameEn: '${seed.$3}$tierNameEn',
          descIt: seed.$6,
          descEn: seed.$6,
          weaponIds: {seed.$4},
          costumeIds: {seed.$5},
          damageBonus: 2 + tier,
          defenseBonus: 1 + tier,
          shieldBonus: 10 + tier * 5,
          oculumBonus: i == 0 ? 1 : (tier == 2 ? 1 : 0),
          critBonus: 2 + tier,
          victoryChanceBonus: 2 + tier,
        ),
      );
    }
    return sets;
  }

  static const List<_DifficultyOption> _difficultyOptions = [
    _DifficultyOption(
      id: 'very_easy',
      nameIt: 'Molto Facile',
      nameEn: 'Very Easy',
      multiplier: 0.62,
      unlockedByDefault: true,
    ),
    _DifficultyOption(
      id: 'easy',
      nameIt: 'Facile',
      nameEn: 'Easy',
      multiplier: 0.78,
      unlockedByDefault: true,
    ),
    _DifficultyOption(
      id: 'normal',
      nameIt: 'Normale',
      nameEn: 'Normal',
      multiplier: 1.0,
      unlockedByDefault: true,
    ),
    _DifficultyOption(
      id: 'hard',
      nameIt: 'Difficile',
      nameEn: 'Hard',
      multiplier: 1.22,
      unlockedByDefault: false,
    ),
    _DifficultyOption(
      id: 'very_hard',
      nameIt: 'Molto Difficile',
      nameEn: 'Very Hard',
      multiplier: 1.48,
      unlockedByDefault: false,
    ),
    _DifficultyOption(
      id: 'oculum',
      nameIt: 'Oculum',
      nameEn: 'Oculum',
      multiplier: 1.85,
      unlockedByDefault: false,
    ),
  ];

  List<_DungeonArt> _generateArts() {
    const formsIt = [
      'Occhio Sepolto',
      'Palpebra Spezzata',
      'Corona Cieca',
      'Risveglio Senza Storia',
    ];

    const formsEn = [
      'Buried Eye',
      'Broken Eyelid',
      'Blind Crown',
      'Storyless Awakening',
    ];

    final arts = <_DungeonArt>[
      const _DungeonArt(
        nameIt: 'Art del Fuoco',
        nameEn: 'Fire Art',
        descIt:
            'Prima Art elementale. Brucia, consuma e lascia cicatrici luminose.',
        descEn:
            'First elemental Art. It burns, consumes and leaves glowing scars.',
        effectId: 'fire_start_art',
        elementId: 'fire',
        unlockedByDefault: true,
        index: 1,
      ),
      const _DungeonArt(
        nameIt: 'Art del Vento',
        nameEn: 'Wind Art',
        descIt:
            'Seconda Art elementale. Taglia l’aria, aumenta combo e schivata.',
        descEn: 'Second elemental Art. It cuts air, increases combo and dodge.',
        effectId: 'wind_start_art',
        elementId: 'wind',
        unlockedByDefault: true,
        index: 2,
      ),
      const _DungeonArt(
        nameIt: 'Art dell’Acqua',
        nameEn: 'Water Art',
        descIt:
            'Terza Art elementale. Cura, rallenta e protegge come una lacrima viva.',
        descEn:
            'Third elemental Art. It heals, slows and protects like a living tear.',
        effectId: 'water_start_art',
        elementId: 'water',
        unlockedByDefault: true,
        index: 3,
      ),
      const _DungeonArt(
        nameIt: 'Art della Terra',
        nameEn: 'Earth Art',
        descIt:
            'Quarta Art elementale. Alza Scudo, ossa e mura sotto la pelle.',
        descEn:
            'Fourth elemental Art. It raises Shield, bones and walls under the skin.',
        effectId: 'earth_start_art',
        elementId: 'earth',
        unlockedByDefault: true,
        index: 4,
      ),
      const _DungeonArt(
        nameIt: 'Art di Necromanzia Acquatica',
        nameEn: 'Aquatic Necromancy Art',
        descIt:
            'Tiene viva temporaneamente una creatura affogata con i suoi ricordi. Costa 3 Oculum e dura 3 turni.',
        descEn:
            'Temporarily keeps a drowned creature alive with its memories. Costs 3 Oculum and lasts 3 turns.',
        effectId: 'water_necromancy_art',
        elementId: 'water',
        unlockedByDefault: false,
        index: 5,
      ),
      const _DungeonArt(
        nameIt: 'Fuoco di Asher',
        nameEn: 'Asher Fire',
        descIt:
            'Art contrattuale. Ti offre bruciatura fisica, fusione col fuoco o uno sguardo che migliora la run.',
        descEn:
            'Contract Art. Offers physical burn, fire fusion or a watching gaze that improves the run.',
        effectId: 'asher_fire_art',
        elementId: 'fire',
        unlockedByDefault: false,
        index: 6,
      ),
      const _DungeonArt(
        nameIt: 'Emblem Art dei Mille Fuochi',
        nameEn: 'Thousand Fires Emblem Art',
        descIt:
            'Art Hideana. Ogni colpo cambia fiamma e cresce contro gruppi e boss.',
        descEn:
            'Hidean Art. Every hit changes flame and grows against groups and bosses.',
        effectId: 'thousand_fires_emblem_art',
        elementId: 'fire',
        unlockedByDefault: false,
        index: 7,
      ),
      const _DungeonArt(
        nameIt: 'Art del Passo Arcano',
        nameEn: 'Arcane Step Art',
        descIt:
            'Art rapida da arena. Scatti brevi, colpi circolari e pressione elementale.',
        descEn:
            'Fast arena Art. Short dashes, circular hits and elemental pressure.',
        effectId: 'arcane_step_art',
        elementId: 'lightning',
        unlockedByDefault: false,
        index: 8,
      ),
      const _DungeonArt(
        nameIt: 'Art degli Anelli di Gelo',
        nameEn: 'Frost Rings Art',
        descIt: 'Evoca cerchi di gelo per controllare spazio, combo e difesa.',
        descEn: 'Summons frost rings to control space, combos and defense.',
        effectId: 'frost_rings_art',
        elementId: 'ice',
        unlockedByDefault: false,
        index: 9,
      ),
      const _DungeonArt(
        nameIt: 'Art dell Orbita di Brace',
        nameEn: 'Ember Orbit Art',
        descIt: 'Braci orbitanti, dash offensivi e fuoco che premia il ritmo.',
        descEn:
            'Orbiting embers, offensive dashes and fire that rewards rhythm.',
        effectId: 'ember_orbit_art',
        elementId: 'fire',
        unlockedByDefault: false,
        index: 10,
      ),
      const _DungeonArt(
        nameIt: 'Art del Sigillo di Marea',
        nameEn: 'Tidal Seal Art',
        descIt:
            'Sigilli d acqua che rimbalzano tra cura, controllo e danno ad area.',
        descEn:
            'Water seals that bounce between healing, control and area damage.',
        effectId: 'tidal_seal_art',
        elementId: 'water',
        unlockedByDefault: false,
        index: 11,
      ),
      const _DungeonArt(
        nameIt: 'Oculum Art Hoshy',
        nameEn: 'Hoshy Oculum Art',
        descIt:
            'Art stellare di Hoshy: comete piccole, esplosioni a contatto e una forma luminosa che alza VC e CM.',
        descEn:
            'Hoshy star Art: small comets, contact bursts and a luminous form that raises VC and CM.',
        effectId: 'hoshy_oculum_art',
        elementId: 'dream',
        unlockedByDefault: false,
        index: 12,
      ),
      const _DungeonArt(
        nameIt: 'Oculum Art: Autunno',
        nameEn: 'Oculum Art: Autumn',
        descIt:
            'Foglie secche, vento, Oculum che si consuma e Materia che nasce dalla morte.',
        descEn: 'Dry leaves, wind, spent Oculum and Materia born from death.',
        effectId: 'autumn_oculum_art',
        elementId: 'wind',
        unlockedByDefault: false,
        index: 13,
      ),
      const _DungeonArt(
        nameIt: 'Martial Art: Swiftness Art',
        nameEn: 'Martial Art: Swiftness Art',
        descIt:
            'Arte marziale rapida: colpi concatenati, sparizione e vantaggi sui critici.',
        descEn:
            'Fast martial art: chained hits, vanishing and critical momentum.',
        effectId: 'swiftness_martial_art',
        elementId: 'neutral',
        unlockedByDefault: false,
        index: 14,
      ),
      const _DungeonArt(
        nameIt: 'Art Scolastica Moderna',
        nameEn: 'Modern School Art',
        descIt:
            'Quaderni rotti, palestra, formule e una lavagna che non accetta la morte al primo tentativo.',
        descEn:
            'Broken notebooks, gym drills, formulas and a blackboard that refuses death on the first attempt.',
        effectId: 'modern_school_art',
        elementId: 'oculum',
        unlockedByDefault: true,
        index: 15,
      ),
      const _DungeonArt(
        nameIt: 'Kingi Art',
        nameEn: 'Kingi Art',
        descIt:
            'Art blu e cupa: controllo del blu, fiamme, fulmini e una logica da robot troppo sicuro di se.',
        descEn:
            'Dark blue Art: blue control, flames, lightning and the logic of an overconfident robot.',
        effectId: 'kingi_blue_art',
        elementId: 'lightning',
        unlockedByDefault: true,
        index: 16,
      ),
      const _DungeonArt(
        nameIt: 'Defiled Art di Postea',
        nameEn: 'Postea Defiled Art',
        descIt:
            'Rarissima. Si sblocca con pagine chiamate Kingi o Ki Korangi e permette di trovare pezzi di Metallo Runico Postea da 1/2 kg.',
        descEn:
            'Very rare. Unlocked by pages named Kingi or Ki Korangi and enables 1/2 kg Postea Runic Metal pieces.',
        effectId: 'defiled_postea_art',
        elementId: 'postea',
        unlockedByDefault: false,
        index: 17,
      ),
    ];

    int index = 18;
    for (final element in _elements) {
      if (element.id == 'neutral') continue;
      for (int i = 0; i < formsIt.length; i++) {
        arts.add(
          _DungeonArt(
            nameIt: 'Art ${formsIt[i]} di ${element.nameIt}',
            nameEn: '${element.nameEn} ${formsEn[i]} Art',
            descIt:
                'Art di ${element.nameIt}. L’Oculum ${element.verbIt} la materia e lascia una firma nel Fato.',
            descEn:
                '${element.nameEn} Art. Oculum ${element.verbEn} Materia and leaves a signature in Fate.',
            effectId: '${element.id}_art_${i + 1}',
            elementId: element.id,
            unlockedByDefault: false,
            index: index,
          ),
        );
        index++;
      }
    }

    const expertNamesIt = [
      'Sguardo dei Trentasei Tagli',
      'Palpebra del Nido Nero',
      'Corona dell’Occhio Calmo',
      'Lacrima che Morde il Sole',
      'Respiro della Luna Sporca',
      'Mano che Spegne le Stelle',
      'Coro di Pupille Secche',
      'Fioritura del Terzo Sangue',
      'Sale nelle Orbite',
      'Nervo di Vapium Vivo',
      'Arco dell’Occhio Inverso',
      'Marea dei Ricordi Affogati',
      'Tomba del Fuoco Gentile',
      'Vento con Denti da Bambino',
      'Pietra che Sogna Carne',
      'Tuono della Palpebra Chiusa',
      'Lama dei Mille Riflessi',
      'Nebbia del Fato Stanco',
      'Ruggine dell’Angelo Basso',
      'Occhio che Imita il Vuoto',
      'Radice delle Dodici Stanze',
      'Nodo delle Lacrime Nere',
      'Scudo della Pupilla Antica',
      'Bestia Sotto il Nome',
      'Elegia dei Piccoli Oculiani',
      'Carne della Stella Fredda',
      'Gabbia di Luce Malata',
      'Morso della Corona Umida',
      'Specchio senza Palpebra',
      'Cenere che Benedice',
      'Fame dell’Oculum Bianco',
      'Canto del Core Viola',
      'Piuma dell’Obser Sepolto',
      'Benedizione di Baghest Vuoto',
      'Filo della Rinascita Cruda',
      'Esperto di Oculum',
    ];
    const expertNamesEn = [
      'Gaze of Thirty-Six Cuts',
      'Black Nest Eyelid',
      'Calm Eye Crown',
      'Tear that Bites the Sun',
      'Dirty Moon Breath',
      'Hand that Extinguishes Stars',
      'Choir of Dry Pupils',
      'Third Blood Bloom',
      'Salt inside the Orbits',
      'Living Vapium Nerve',
      'Inverted Eye Arc',
      'Tide of Drowned Memories',
      'Tomb of Gentle Fire',
      'Wind with Child Teeth',
      'Stone that Dreams Flesh',
      'Closed Eyelid Thunder',
      'Blade of Thousand Reflections',
      'Mist of Tired Fate',
      'Low Angel Rust',
      'Eye that Mimics the Void',
      'Root of the Twelve Rooms',
      'Knot of Black Tears',
      'Ancient Pupil Shield',
      'Beast Under the Name',
      'Elegy of Small Oculians',
      'Cold Star Flesh',
      'Cage of Sick Light',
      'Wet Crown Bite',
      'Mirror without Eyelid',
      'Ash that Blesses',
      'White Oculum Hunger',
      'Purple Core Song',
      'Buried Obser Feather',
      'Empty Baghest Blessing',
      'Raw Rebirth Thread',
      'Oculum Expert',
    ];
    final expertElements = [
      'slash',
      'shadow',
      'oculum',
      'sun',
      'moon',
      'star',
      'sound',
      'flora',
      'bone',
      'vapium',
      'gravity',
      'water',
      'fire',
      'wind',
      'earth',
      'lightning',
      'mirror',
      'fate',
      'holy',
      'void',
      'nature',
      'blood',
      'shield',
      'beast',
      'oculum',
      'ice',
      'light',
      'water',
      'mirror',
      'fire',
      'oculum',
      'poison',
      'neutral',
      'shadow',
      'rebirth',
      'oculum',
    ];
    for (var i = 0; i < 36; i++) {
      arts.add(
        _DungeonArt(
          nameIt: 'Art Esperta — ${expertNamesIt[i]}',
          nameEn: 'Expert Art — ${expertNamesEn[i]}',
          descIt:
              'Art unica sbloccata dall’evoluzione di Principiante. Porta un frammento del piano ${((i % 12) + 1)}.',
          descEn:
              'Unique Art unlocked by Beginner evolution. It carries a fragment of floor ${((i % 12) + 1)}.',
          effectId: 'expert_oculum_art_${i + 1}',
          elementId: expertElements[i],
          unlockedByDefault: false,
          index: index + i,
        ),
      );
    }

    return arts;
  }

  List<_EnemyTemplate> _generateEnemies() {
    final bodiesIt = [
      'Demone della Piaga',
      'Uomo in Posizione Fetale',
      'Uomo Decapitato',
      'Scheletro Runico',
      'Mimic delle Lacrime Nere',
      'Cane di Cenere',
      'Pellegrino Senza Volto',
      'Occhio Caduto',
      'Slime di Muraglia',
      'Monaco con la Bocca Cucita',
      'Custode con Mani Inverse',
      'Bambola di Vapium',
      'Angelo Sporco della Palpebra',
      'Ragno degli Obser Falsi',
      'Fabbro Senza Lingua',
      'Santo Vuoto Piccolo',
    ];

    final bodiesEn = [
      'Plague Demon',
      'Man in Fetal Position',
      'Headless Man',
      'Runic Skeleton',
      'Black-Tear Mimic',
      'Ash Hound',
      'Faceless Pilgrim',
      'Fallen Eye',
      'Wall Slime',
      'Sewn-Mouth Monk',
      'Keeper with Inverted Hands',
      'Vapium Doll',
      'Dirty Eyelid Angel',
      'False-Obser Spider',
      'Tongueless Blacksmith',
      'Small Hollow Saint',
    ];

    const fixedBodyElements = {
      'Uomo in Posizione Fetale': 'psyche',
      'Uomo Decapitato': 'blood',
    };

    final list = <_EnemyTemplate>[];
    for (final element in _elements.where((e) => e.id != 'neutral')) {
      for (int i = 0; i < bodiesIt.length; i++) {
        final fixedElement = fixedBodyElements[bodiesIt[i]];
        if (fixedElement != null && element.id != fixedElement) continue;
        list.add(
          _EnemyTemplate(
            nameIt: '${bodiesIt[i]} di ${element.nameIt}',
            nameEn: '${element.nameEn} ${bodiesEn[i]}',
            descIt:
                'Creatura di ${element.nameIt}. Il suo Oculum ${element.verbIt} senza pietà.',
            descEn:
                '${element.nameEn} creature. Its Oculum ${element.verbEn} without mercy.',
            elementId: element.id,
            hpMod: i % 4,
            atkMod: (i + 1) % 5,
            defMod: i % 3,
          ),
        );
      }
    }

    for (final element in _elements.where((e) => e.id != 'neutral')) {
      list.add(
        _EnemyTemplate(
          nameIt: 'Boss — Corona Cieca di ${element.nameIt}',
          nameEn: 'Boss — Blind Crown of ${element.nameEn}',
          descIt: 'Boss elementale. Non cammina: viene ricordato dalla stanza.',
          descEn: 'Elemental boss. It does not walk: the room remembers it.',
          elementId: element.id,
          hpMod: 8,
          atkMod: 5,
          defMod: 4,
          boss: true,
        ),
      );
    }
    list.addAll(const [
      _EnemyTemplate(
        nameIt: 'Slime Blu',
        nameEn: 'Blue Slime',
        descIt:
            'Tipo Slime. Range livello 1/9, senza Grado. Drop chiave: Slime Skin; con 20 Slime Skin il colpo finale passa da impossibile a molto difficile.',
        descEn:
            'Slime type. Level range 1/9, no Grade. Key drop: Slime Skin; with 20 Slime Skins, the final blow shifts from impossible to very hard.',
        elementId: 'slime',
        hpMod: 0,
        atkMod: 1,
        defMod: 0,
      ),
      _EnemyTemplate(
        nameIt: 'Slime Blu con Elmetto',
        nameEn: 'Helmeted Blue Slime',
        descIt:
            'Slime Blu corazzato. La pelle assorbe male il fuoco ma rimbalza bene sui colpi deboli.',
        descEn:
            'Armored Blue Slime. Its skin hates fire but bounces weak hits well.',
        elementId: 'slime',
        hpMod: 1,
        atkMod: 1,
        defMod: 2,
      ),
      _EnemyTemplate(
        nameIt: 'Patalpa Dolce',
        nameEn: 'Sweet Patalpa',
        descIt:
            'Una talpa patata. Stats base segnate: 15 / 3 / 15. Generazione: spende un azione e 10 Oculum per richiamare una Patalpa Dolce con le stats attuali del Patalpa più debole, senza Generazione, cooldown 10 turni. Palata: con critico applica Stun x critico e +2 danni x livello, cooldown 3 turni. Rigenerazione: si mette per metà sotto terra, raddoppia CM, non può tirare e rigenera 25% HP ogni turno, cooldown 2 turni.',
        descEn:
            'A potato mole. Base stats noted: 15 / 3 / 15. Generation: spends one action and 10 Oculum to call a Sweet Patalpa with the current stats of the weakest Patalpa, without Generation, cooldown 10 turns. Shovel Slam: on critical applies Stun x critical and +2 damage x level, cooldown 3 turns. Regeneration: buries halfway, doubles CM, cannot roll and regenerates 25% HP each turn, cooldown 2 turns.',
        elementId: 'flora',
        hpMod: 2,
        atkMod: 3,
        defMod: 4,
      ),
      _EnemyTemplate(
        nameIt: 'Baby Rock Rhino',
        nameEn: 'Baby Rock Rhino',
        descIt:
            'Tipo Costrutto, livello 1/40. Carica Devastante, Scatto Arretrante e Scatto Roccioso sono ancora grezzi ma pericolosi.',
        descEn:
            'Construct type, level 1/40. Devastating Charge, Backward Dash and Rocky Dash are still rough but dangerous.',
        elementId: 'earth',
        hpMod: 2,
        atkMod: 3,
        defMod: 3,
      ),
      _EnemyTemplate(
        nameIt: 'Rock Rhino',
        nameEn: 'Rock Rhino',
        descIt:
            'Costrutto di Grado I/III. Carica Finale: aura rocciosa, spinta e danni Oculum x2, x4 se schiaccia contro l ambiente.',
        descEn:
            'Grade I/III Construct. Final Charge: rocky aura, knockback and Oculum x2 damage, x4 if it pins against terrain.',
        elementId: 'earth',
        hpMod: 5,
        atkMod: 5,
        defMod: 5,
      ),
      _EnemyTemplate(
        nameIt: 'Shadow Mimic',
        nameEn: 'Shadow Mimic',
        descIt:
            'Tipo Shadow, livello 0/40. Shadow Eye riduce statistiche, Magic Item crea l oggetto utile, Teletrasporto Tenebroso cerca la schiena.',
        descEn:
            'Shadow type, level 0/40. Shadow Eye lowers stats, Magic Item creates the useful item, Dark Teleport seeks your back.',
        elementId: 'shadow',
        hpMod: 2,
        atkMod: 3,
        defMod: 1,
      ),
      _EnemyTemplate(
        nameIt: 'Cultista degli Occhi Viola',
        nameEn: 'Cultist of Purple Eyes',
        descIt:
            'Fanatico oculare. Sguardo Marcio corrode difesa, Pressione Corrotta rallenta e schiaccia il ritmo.',
        descEn:
            'Ocular fanatic. Rotting Gaze erodes defense, Corrupted Pressure slows and crushes rhythm.',
        elementId: 'oculum',
        hpMod: 3,
        atkMod: 4,
        defMod: 2,
      ),
      _EnemyTemplate(
        nameIt: 'Prince Slime',
        nameEn: 'Prince Slime',
        descIt:
            'Miniboss Slime, livello 9/100. Tornado Slime, Schianto del Re e Spadata del Re Slime preparano il trono.',
        descEn:
            'Slime miniboss, level 9/100. Slime Tornado, King Crash and Slime King Sword prepare the throne.',
        elementId: 'slime',
        hpMod: 5,
        atkMod: 4,
        defMod: 3,
        boss: true,
      ),
      _EnemyTemplate(
        nameIt: 'King Slime',
        nameEn: 'King Slime',
        descIt:
            'Boss Slime di Grado IV/IX. Apertura: Armata Slime; gli slime evocati morti gli ridanno Oculum.',
        descEn:
            'Grade IV/IX Slime boss. Opening: Slime Army; each summoned slime that dies restores Oculum to the king.',
        elementId: 'slime',
        hpMod: 8,
        atkMod: 6,
        defMod: 4,
        boss: true,
      ),
      _EnemyTemplate(
        nameIt: 'Incubo senza Risveglio Infante',
        nameEn: 'Infant Nightmare Without Awakening',
        descIt:
            'Mostro errante Mini Boss. Raggio Penetrante, Resistenza e Pestone Esplosivo in forma giovane.',
        descEn:
            'Wandering miniboss. Penetrating Ray, Resistance and Explosive Stomp in young form.',
        elementId: 'dream',
        hpMod: 7,
        atkMod: 6,
        defMod: 4,
        boss: true,
      ),
      _EnemyTemplate(
        nameIt: 'Vero Incubo senza Risveglio',
        nameEn: 'True Nightmare Without Awakening',
        descIt:
            'Boss errante Grado V/X. A metà vita ottiene 5000 Scudo e uno Scudo di Salvataggio nella scheda completa.',
        descEn:
            'Grade V/X wandering boss. At half HP, the full sheet grants 5000 Shield and a Saving Shield.',
        elementId: 'dream',
        hpMod: 12,
        atkMod: 9,
        defMod: 8,
        boss: true,
      ),
    ]);
    return list;
  }

  List<_ShopItem> _generateShopItems() {
    final items = <_ShopItem>[
      const _ShopItem(
        nameIt: 'Pane di Skelly',
        nameEn: 'Skelly Bread',
        descIt: 'Cura subito 18 HP.',
        descEn: 'Immediately heals 18 HP.',
        costObser: 5,
        costDust: 0,
        effectId: 'heal_18',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Mappa delle Palpebre',
        nameEn: 'Eyelid Map',
        descIt: 'Aumenta la probabilità di eventi utili.',
        descEn: 'Increases useful event chance.',
        costObser: 9,
        costDust: 0,
        effectId: 'map',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Piuma Indaco',
        nameEn: 'Indigo Feather',
        descIt: '+1 schivata e +1 difesa.',
        descEn: '+1 dodge and +1 defense.',
        costObser: 16,
        costDust: 2,
        effectId: 'dodge_defense',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Ciondolo della Seconda Luna',
        nameEn: 'Second Moon Charm',
        descIt: 'Una volta per run, se cadi a 0 HP resti a 1 HP.',
        descEn: 'Once per run, if you fall to 0 HP you remain at 1 HP.',
        costObser: 20,
        costDust: 2,
        effectId: 'second_chance',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Sigillo Oculiano Piccolo',
        nameEn: 'Small Oculian Seal',
        descIt: '+1 carica Oculum.',
        descEn: '+1 Oculum charge.',
        costObser: 10,
        costDust: 1,
        effectId: 'oculum_charge_1',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Mirino della Materia Cieca',
        nameEn: 'Blind Materia Sight',
        descIt:
            'Sblocca gli attacchi CM base nella run. Una lente che misura il corpo invece dell’occhio.',
        descEn:
            'Unlocks basic CM attacks during the run. A lens that measures the body instead of the eye.',
        costObser: 13,
        costDust: 1,
        effectId: 'unlock_cm_attack',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Cerchio a Frammenti',
        nameEn: 'Fragment Circle',
        descIt: 'Sblocca AoE VC nella run. Il colpo rimbalza tra più nemici.',
        descEn:
            'Unlocks VC AoE during the run. The strike bounces across multiple enemies.',
        costObser: 15,
        costDust: 1,
        effectId: 'unlock_aoe_vc',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Compasso della Materia Rotta',
        nameEn: 'Broken Materia Compass',
        descIt:
            'Sblocca AoE CM nella run. Utile contro branchi e boss con servitori.',
        descEn:
            'Unlocks CM AoE during the run. Useful against packs and bosses with adds.',
        costObser: 18,
        costDust: 2,
        effectId: 'unlock_aoe_cm',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Pergamena Occulta — Doppio Respiro',
        nameEn: 'Occult Scroll — Double Breath',
        descIt:
            '+1 scelta negli eventi di crescita e più possibilità di trovare camere élite.',
        descEn:
            '+1 choice in growth events and higher chance to find elite chambers.',
        costObser: 22,
        costDust: 3,
        effectId: 'scroll_double_breath',
      ),
      const _ShopItem(
        nameIt: 'Pergamena Occulta — Occhio Rimbalzante',
        nameEn: 'Occult Scroll — Bouncing Eye',
        descIt:
            'Gli attacchi elementali possono colpire un secondo nemico con danno ridotto.',
        descEn: 'Elemental attacks may hit a second enemy with reduced damage.',
        costObser: 24,
        costDust: 3,
        effectId: 'scroll_bouncing_eye',
      ),

      const _ShopItem(
        nameIt: 'Vitalium Grezzo',
        nameEn: 'Raw Vitalium',
        descIt: 'Aggiunge 1 Vitalium Grezzo allo zaino rapido.',
        descEn: 'Adds 1 Raw Vitalium to the quick bag.',
        costObser: 6,
        costDust: 0,
        effectId: 'potion_minor',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Vitalium Ridefinito',
        nameEn: 'Redefined Vitalium',
        descIt: 'Aggiunge 1 Vitalium Ridefinito allo zaino rapido.',
        descEn: 'Adds 1 Redefined Vitalium to the quick bag.',
        costObser: 14,
        costDust: 1,
        effectId: 'potion_major',
      ),
      const _ShopItem(
        nameIt: 'Fiala Scudo',
        nameEn: 'Shield Vial',
        descIt: 'Aggiunge 1 fiala scudo allo zaino rapido.',
        descEn: 'Adds 1 shield vial to the quick bag.',
        costObser: 12,
        costDust: 1,
        effectId: 'potion_shield',
      ),
      const _ShopItem(
        nameIt: 'Fiala Oculum',
        nameEn: 'Oculum Vial',
        descIt: 'Aggiunge 1 fiala Oculum allo zaino rapido.',
        descEn: 'Adds 1 Oculum vial to the quick bag.',
        costObser: 16,
        costDust: 2,
        effectId: 'potion_oculum',
      ),
      const _ShopItem(
        nameIt: 'Fumo Fuga',
        nameEn: 'Escape Smoke',
        descIt: 'Aggiunge 1 fumo rapido per fuggire dai fight normali.',
        descEn: 'Adds 1 quick smoke to flee normal fights.',
        costObser: 18,
        costDust: 1,
        effectId: 'potion_smoke',
      ),
      const _ShopItem(
        nameIt: 'Solvente',
        nameEn: 'Solvent',
        descIt: 'Aggiunge 1 solvente rapido per pulire debuff.',
        descEn: 'Adds 1 quick solvent to clean debuffs.',
        costObser: 11,
        costDust: 1,
        effectId: 'potion_cleanse',
      ),
      const _ShopItem(
        nameIt: 'Contratto Arma',
        nameEn: 'Weapon Contract',
        descIt: 'Sblocca una nuova arma iniziale casuale più avanzata.',
        descEn: 'Unlocks a new advanced random starting weapon.',
        costObser: 34,
        costDust: 6,
        effectId: 'unlock_random_weapon',
      ),
      const _ShopItem(
        nameIt: 'Invito Alleato',
        nameEn: 'Ally Invitation',
        descIt: 'Sblocca un NPC buono casuale non ancora trovato.',
        descEn: 'Unlocks a random good NPC not yet found.',
        costObser: 30,
        costDust: 5,
        effectId: 'unlock_random_npc',
      ),
      const _ShopItem(
        nameIt: 'Gadget del Porto',
        nameEn: 'Harbor Gadget',
        descIt:
            '+1 danno e +1 difesa run. Titolo item debole della città commerciale.',
        descEn:
            '+1 run damage and +1 run defense. Weak title item from the trade city.',
        costObser: 7,
        costDust: 0,
        effectId: 'trade_gadget_weak',
        firstThreeRunsOnly: true,
      ),
      const _ShopItem(
        nameIt: 'Gadget degli Affogati',
        nameEn: 'Drowned Gadget',
        descIt:
            '+2 Oculum e +1 difesa run. Piccolo oggetto della magia acquatica.',
        descEn: '+2 Oculum and +1 run defense. Small item from aquatic magic.',
        costObser: 16,
        costDust: 1,
        effectId: 'trade_gadget_drowned',
      ),
    ];

    for (final element in _elements.where((e) => e.id != 'neutral')) {
      items.addAll([
        _ShopItem(
          nameIt: 'Benda di Resistenza — ${element.nameIt}',
          nameEn: '${element.nameEn} Resistance Bandage',
          descIt:
              '+2 resistenza a ${element.nameIt}. Sa di pioggia vecchia e sangue asciutto.',
          descEn:
              '+2 ${element.nameEn} resistance. It smells of old rain and dry blood.',
          costObser: 8,
          costDust: 0,
          effectId: 'resist',
          elementId: element.id,
          resist: 2,
          firstThreeRunsOnly: true,
        ),
        _ShopItem(
          nameIt: 'Occhio Scheggiato di ${element.nameIt}',
          nameEn: 'Chipped ${element.nameEn} Eye',
          descIt: '+4 resistenza a ${element.nameIt}, +1 danno run.',
          descEn: '+4 ${element.nameEn} resistance, +1 run damage.',
          costObser: 14,
          costDust: 1,
          effectId: 'resist_damage',
          elementId: element.id,
          resist: 4,
        ),
        _ShopItem(
          nameIt: 'Reliquia XII — Palpebra di ${element.nameIt}',
          nameEn: 'Relic XII — ${element.nameEn} Eyelid',
          descIt: '+7 resistenza a ${element.nameIt}, +2 difesa, +2 Oculum.',
          descEn: '+7 ${element.nameEn} resistance, +2 defense, +2 Oculum.',
          costObser: 32,
          costDust: 5,
          effectId: 'relic_resist',
          elementId: element.id,
          resist: 7,
        ),
      ]);
    }
    return items;
  }

  List<_UniqueDrop> _generateDrops() {
    final drops = <_UniqueDrop>[];
    int i = 0;
    for (final element in _elements.where((e) => e.id != 'neutral')) {
      drops.addAll([
        _UniqueDrop(
          id: '${element.id}_core',
          nameIt: 'Core Unico di ${element.nameIt}',
          nameEn: 'Unique ${element.nameEn} Core',
          descIt:
              'Puoi incastonarlo nell’arma o venderlo al fabbro. Dentro pulsa un occhio minuscolo.',
          descEn:
              'You can socket it into your weapon or sell it to the blacksmith. A tiny eye pulses inside.',
          elementId: element.id,
          damageBonus: 2 + (i % 3),
          defenseBonus: i % 2,
          resistBonus: 2 + (i % 4),
          sellObser: 8 + i,
          sellDust: 1 + i % 3,
        ),
        _UniqueDrop(
          id: '${element.id}_tear',
          nameIt: 'Lacrima Unica di ${element.nameIt}',
          nameEn: 'Unique ${element.nameEn} Tear',
          descIt:
              'Una lacrima dura. Sembra piangere da prima della tua nascita.',
          descEn:
              'A hard tear. It looks like it has cried since before your birth.',
          elementId: element.id,
          damageBonus: 1,
          defenseBonus: 1 + (i % 3),
          resistBonus: 3,
          sellObser: 6 + i,
          sellDust: 1,
        ),
      ]);
      i++;
    }
    drops.addAll(const [
      _UniqueDrop(
        id: 'slime_skin_material',
        nameIt: 'Slime Skin',
        nameEn: 'Slime Skin',
        descIt:
            'Drop da Slime Blu. Materiale elastico: 20 pelli rendono il colpo finale contro Slime molto difficile invece di impossibile. Titolo collegato: Slime Skin.',
        descEn:
            'Blue Slime drop. Elastic material: 20 skins make the final blow against Slimes very hard instead of impossible. Linked Title: Slime Skin.',
        elementId: 'slime',
        damageBonus: 0,
        defenseBonus: 2,
        resistBonus: 2,
        sellObser: 5,
        sellDust: 1,
      ),
      _UniqueDrop(
        id: 'sweet_patalpa_food',
        nameIt: 'Patalpa Dolce',
        nameEn: 'Sweet Patalpa',
        descIt:
            'Drop cibo: 250gr, Cibo 2/1. Mangiarla nella scheda completa da +1 a tutte le stats per un ora. Una talpa patata particolarmente prelibata quanto malvagia.',
        descEn:
            'Food drop: 250g, Food 2/1. In the full sheet, eating it grants +1 to all stats for one hour. A potato mole, especially delicious and wicked.',
        elementId: 'flora',
        damageBonus: 1,
        defenseBonus: 1,
        resistBonus: 2,
        sellObser: 7,
        sellDust: 1,
      ),
      _UniqueDrop(
        id: 'sweet_patalpa_shovel_drop',
        nameIt: 'Pala del Patalpa Dolce',
        nameEn: 'Sweet Patalpa Shovel',
        descIt:
            'Drop raro su critico contro Patalpa Dolce. Buff narrativo: +4 VC e accesso a Palata; punto cieco -2 percezione. La pala si adatta alla stazza del Patalpa e cresce con la sua fame.',
        descEn:
            'Rare critical drop from Sweet Patalpa. Narrative buff: +4 VC and access to Shovel Slam; blind spot -2 perception. The shovel adapts to the Patalpa size and grows with its hunger.',
        elementId: 'flora',
        damageBonus: 4,
        defenseBonus: 1,
        resistBonus: 2,
        sellObser: 18,
        sellDust: 3,
      ),
      _UniqueDrop(
        id: 'nightmare_flesh_scraps',
        nameIt: 'Scarti di Carne',
        nameEn: 'Flesh Scraps',
        descIt:
            'Drop base dell Incubo senza Risveglio. Cibo scadente, 100gr, sazieta 1/3, putrefazione 2 sessioni; 100gr meno putridi possono risanare massimo una sessione.',
        descEn:
            'Base drop from the Nightmare Without Awakening. Poor food, 100g, satiety 1/3, rots in 2 sessions; less rotten 100g can restore at most one session.',
        elementId: 'dream',
        damageBonus: 1,
        defenseBonus: 0,
        resistBonus: 1,
        sellObser: 4,
        sellDust: 1,
      ),
      _UniqueDrop(
        id: 'hard_bones_material',
        nameIt: 'Ossa Dure',
        nameEn: 'Hard Bones',
        descIt:
            'Materiale da Incubo adulto: 1kg. Baby: 1d3 ossa; adulto: 1d4+2 Ossa Dure.',
        descEn:
            'Material from adult Nightmare: 1kg. Baby: 1d3 bones; adult: 1d4+2 Hard Bones.',
        elementId: 'bone',
        damageBonus: 1,
        defenseBonus: 2,
        resistBonus: 3,
        sellObser: 9,
        sellDust: 2,
      ),
      _UniqueDrop(
        id: 'young_nightmare_heart',
        nameIt: 'Cuore di Incubo senza Risveglio Giovane',
        nameEn: 'Young Nightmare Without Awakening Heart',
        descIt:
            'Cuore giovane dell Incubo. Conserva il ricordo del Raggio Penetrante e del Pestone Esplosivo.',
        descEn:
            'Young Nightmare heart. It preserves the memory of Penetrating Ray and Explosive Stomp.',
        elementId: 'dream',
        damageBonus: 4,
        defenseBonus: 1,
        resistBonus: 4,
        sellObser: 22,
        sellDust: 4,
      ),
      _UniqueDrop(
        id: 'true_nightmare_heart',
        nameIt: 'Cuore di Vero Incubo senza Risveglio',
        nameEn: 'True Nightmare Without Awakening Heart',
        descIt:
            'Cuore del vero boss. A metà vita ricordava 5000 Scudo e uno Scudo di Salvataggio.',
        descEn:
            'True boss heart. At half HP it remembered 5000 Shield and a Saving Shield.',
        elementId: 'dream',
        damageBonus: 7,
        defenseBonus: 4,
        resistBonus: 7,
        sellObser: 45,
        sellDust: 8,
      ),
      _UniqueDrop(
        id: 'rock_rhino_rock',
        nameIt: 'Roccia',
        nameEn: 'Rock',
        descIt:
            'Drop Rock Rhino. Materiale scadente, 500gr. Baby: 1d3 Roccia; adulto: 1d4+3 Roccia.',
        descEn:
            'Rock Rhino drop. Poor material, 500g. Baby: 1d3 Rock; adult: 1d4+3 Rock.',
        elementId: 'earth',
        damageBonus: 0,
        defenseBonus: 2,
        resistBonus: 2,
        sellObser: 4,
        sellDust: 1,
      ),
      _UniqueDrop(
        id: 'weak_broken_core',
        nameIt: 'Core Debole Rotto',
        nameEn: 'Weak Broken Core',
        descIt:
            'Materiale da Baby Rock Rhino, 500gr. Vibra quando una carica fallisce.',
        descEn:
            'Material from Baby Rock Rhino, 500g. It vibrates when a charge fails.',
        elementId: 'earth',
        damageBonus: 1,
        defenseBonus: 2,
        resistBonus: 3,
        sellObser: 8,
        sellDust: 2,
      ),
      _UniqueDrop(
        id: 'broken_core',
        nameIt: 'Core Rotto',
        nameEn: 'Broken Core',
        descIt:
            'Materiale da Rock Rhino adulto, 3kg. Tiene memoria di Carica Devastante e Scatto Roccioso.',
        descEn:
            'Material from adult Rock Rhino, 3kg. It remembers Devastating Charge and Rocky Dash.',
        elementId: 'earth',
        damageBonus: 2,
        defenseBonus: 4,
        resistBonus: 4,
        sellObser: 16,
        sellDust: 3,
      ),
      _UniqueDrop(
        id: 'rock_rhino_eye',
        nameIt: 'Occhio di Rock Rhino',
        nameEn: 'Rock Rhino Eye',
        descIt:
            'Con 20 Occhi, il colpo finale contro Rock Rhino passa da impossibile a molto difficile. Titolo collegato: Possessore dell Occhio della Terra.',
        descEn:
            'With 20 Eyes, the final blow against Rock Rhino shifts from impossible to very hard. Linked Title: Bearer of the Eye of Earth.',
        elementId: 'earth',
        damageBonus: 1,
        defenseBonus: 3,
        resistBonus: 5,
        sellObser: 18,
        sellDust: 4,
      ),
      _UniqueDrop(
        id: 'slime_king_crown',
        nameIt: 'Corona del Re Slime',
        nameEn: 'Slime King Crown',
        descIt:
            'Con 20 Corone, il colpo finale contro Re Slime passa da impossibile a molto difficile. Titolo collegato: Re Slime.',
        descEn:
            'With 20 Crowns, the final blow against the Slime King shifts from impossible to very hard. Linked Title: Slime King.',
        elementId: 'slime',
        damageBonus: 3,
        defenseBonus: 2,
        resistBonus: 4,
        sellObser: 24,
        sellDust: 5,
      ),
      _UniqueDrop(
        id: 'shadow_mimic_random_item',
        nameIt: 'Item Casuale del Mimic Ombra',
        nameEn: 'Shadow Mimic Random Item',
        descIt:
            'Drop Shadow Mimic. Il Fato decide quale stat aumentare di +3 e quale cosa togliere in roleplay.',
        descEn:
            'Shadow Mimic drop. Fate chooses which stat gains +3 and what is taken in roleplay.',
        elementId: 'shadow',
        damageBonus: 2,
        defenseBonus: 2,
        resistBonus: 3,
        sellObser: 18,
        sellDust: 3,
      ),
    ]);
    return drops;
  }

  List<_GoodNpc> _generateGoodNpcs() {
    return const [
      _GoodNpc(
        id: 'skelly_bone_innkeeper',
        nameIt: 'Skelly, Oste delle Ossa',
        nameEn: 'Skelly, Bone Innkeeper',
        descIt: 'Cura poco ma spesso. Ride senza polmoni e porta pane secco.',
        descEn:
            'Heals lightly but often. Laughs without lungs and carries dry bread.',
        role: 'healer',
        elementId: 'bone',
      ),
      _GoodNpc(
        id: 'indigo_feather_scout',
        nameIt: 'Esploratrice della Piuma Indaco',
        nameEn: 'Indigo Feather Scout',
        descIt: 'Aumenta schivata e colpisce i bersagli feriti.',
        descEn: 'Increases dodge and strikes wounded targets.',
        role: 'striker',
        elementId: 'wind',
      ),
      _GoodNpc(
        id: 'mute_vapium_squire',
        nameIt: 'Scudiero di Vapium Muto',
        nameEn: 'Mute Vapium Squire',
        descIt: 'Dà Scudo al party e assorbe parte della pressione.',
        descEn: 'Gives Shield to the party and absorbs part of the pressure.',
        role: 'guard',
        elementId: 'vapium',
      ),
      _GoodNpc(
        id: 'blind_oculum_girl',
        nameIt: 'Bambina dell’Oculum Bendato',
        nameEn: 'Blindfolded Oculum Girl',
        descIt: 'Buffa Oculum e può ricaricare una carica Oculum.',
        descEn: 'Buffs Oculum and may restore one Oculum charge.',
        role: 'occult',
        elementId: 'moon',
      ),
      _GoodNpc(
        id: 'little_sun_liturgist',
        nameIt: 'Piccola Liturgista del Sole',
        nameEn: 'Little Sun Liturgist',
        descIt: 'Aumenta critico e punisce i boss.',
        descEn: 'Increases critical power and punishes bosses.',
        role: 'buffer',
        elementId: 'sun',
      ),
      _GoodNpc(
        id: 'slime_prince_page',
        nameIt: 'Paggetto del Principe Slime',
        nameEn: 'Prince Slime Page',
        descIt: 'Buffa difesa e lascia scivolare via parte del danno.',
        descEn: 'Buffs defense and lets part of the damage slide away.',
        role: 'guard',
        elementId: 'water',
      ),
      _GoodNpc(
        id: 'shadowless_lampbearer',
        nameIt: 'Portalanterna Senza Ombra',
        nameEn: 'Shadowless Lampbearer',
        descIt: 'Colpisce tutti i nemici con una luce bassa e crudele.',
        descEn: 'Hits all enemies with a low and cruel light.',
        role: 'striker',
        elementId: 'shadow',
      ),
      _GoodNpc(
        id: 'ashen_card_scribe',
        nameIt: 'Scriba delle Carte di Cenere',
        nameEn: 'Ashen Card Scribe',
        descIt:
            'Ogni tanto trasforma una brutta stanza in una scelta migliore.',
        descEn: 'Sometimes turns a bad room into a better choice.',
        role: 'buffer',
        elementId: 'ash',
      ),
      _GoodNpc(
        id: 'skelly_evolved',
        nameIt: 'Skelly Evoluto, Guardiano del Teschio Enorme',
        nameEn: 'Evolved Skelly, Giant Skull Guardian',
        descIt:
            'Versione rarissima di Skelly. Cura, protegge e ride come ossa in una campana.',
        descEn:
            'Very rare version of Skelly. Heals, protects and laughs like bones inside a bell.',
        role: 'guard',
        elementId: 'bone',
      ),
      _GoodNpc(
        id: 'giant_skull_tavernkeeper',
        nameIt: 'Il Taverniere del Teschio Enorme',
        nameEn: 'The Giant Skull Tavernkeeper',
        descIt:
            'Rarissimo. Un enorme cranio scheletrico con mani scheletriche lunghe, inquietante e antico.',
        descEn:
            'Extremely rare. An enormous skeletal skull with long skeletal hands, unsettling and ancient.',
        role: 'occult',
        elementId: 'shadow',
      ),

      _GoodNpc(
        id: 'apothecary_moth',
        nameIt: 'Falena Speziale',
        nameEn: 'Apothecary Moth',
        descIt: 'Aggiunge consumabili allo zaino rapido e migliora le cure.',
        descEn: 'Adds potions to the quick bag and improves healing.',
        role: 'healer',
        elementId: 'dream',
      ),
      _GoodNpc(
        id: 'rusted_duelist',
        nameIt: 'Duellante Arrugginito',
        nameEn: 'Rusted Duelist',
        descIt:
            'Colpisce il bersaglio con meno HP e aumenta i danni contro élite.',
        descEn:
            'Hits the lowest-HP target and increases damage against elites.',
        role: 'striker',
        elementId: 'fire',
      ),
      _GoodNpc(
        id: 'bone_cartographer',
        nameIt: 'Cartografo d’Ossa',
        nameEn: 'Bone Cartographer',
        descIt: 'Rende più frequenti eventi utili e rivela scorciatoie.',
        descEn: 'Makes useful events more frequent and reveals shortcuts.',
        role: 'buffer',
        elementId: 'bone',
      ),
      _GoodNpc(
        id: 'null_nun',
        nameIt: 'Monaca Null',
        nameEn: 'Null Nun',
        descIt:
            'Può indebolire tutti i nemici e annullare parte del loro turno.',
        descEn: 'Can weaken all enemies and cancel part of their turn.',
        role: 'occult',
        elementId: 'nullum',
      ),
      _GoodNpc(
        id: 'slime_smith',
        nameIt: 'Fabbro Slime',
        nameEn: 'Slime Smith',
        descIt: 'Migliora i drop e riduce il costo delle lavorazioni.',
        descEn: 'Improves drops and reduces crafting costs.',
        role: 'guard',
        elementId: 'metal',
      ),

      _GoodNpc(
        id: 'thousand_eyes_child',
        nameIt: 'Bambino dai Mille Occhi',
        nameEn: 'Thousand-Eyed Child',
        descIt:
            'NPC debole e strano: piange troppe lacrime, ma ogni tanto trasforma il pianto in Scudo.',
        descEn:
            'Weak strange NPC: cries too many tears, but sometimes turns crying into Shield.',
        role: 'guard',
        elementId: 'water',
      ),
      _GoodNpc(
        id: 'karma_split_guide',
        nameIt: 'Guida della Bilancia',
        nameEn: 'Scale Guide',
        descIt:
            'NPC sbloccato col Karma positivo: una maschera bianca e nera che trasforma scelte giuste in Scudo Oculum.',
        descEn:
            'NPC unlocked by positive Karma: a black-white mask that turns right choices into Oculum Shield.',
        role: 'buffer',
        elementId: 'oculum',
      ),
      _GoodNpc(
        id: 'debt_black_candle',
        nameIt: 'Candela Nera del Debito',
        nameEn: 'Black Debt Candle',
        descIt:
            'NPC sbloccato col Karma negativo: protegge con Scudo Oculum, ma pretende ferite e scelte dure.',
        descEn:
            'NPC unlocked by negative Karma: protects with Oculum Shield, but asks for wounds and harsh choices.',
        role: 'occult',
        elementId: 'shadow',
      ),
      _GoodNpc(
        id: 'minor_oculian_watcher',
        nameIt: 'Oculiano Minore',
        nameEn: 'Minor Oculian',
        descIt:
            'Un Oculiano minore che ti osservava dal piano 3. Non è fedele, ma è curioso.',
        descEn:
            'A Minor Oculian that watched you from floor 3. Not loyal, but curious.',
        role: 'occult',
        elementId: 'oculum',
      ),
      _GoodNpc(
        id: 'valley_child_of_mother_nature',
        nameIt: 'Valley',
        nameEn: 'Valley',
        descIt:
            'Figlio di Madre Natura. Corpo verde, gonna di foglie, capelli verdi medi e corona di foglie. Tre umani-pianta tragici seguono Valley: carne aperta, fiori interni, rami, foglie e cactus. Valley usa sfere compatte di natura e può far sbocciare i mostri.',
        descEn:
            'Child of Mother Nature. Green body, leaf skirt, medium green hair and leaf crown. Three tragic plant-humans follow Valley: opened flesh, inner flowers, branches, leaves and cactus. Valley uses compact nature spheres and can make monsters bloom.',
        role: 'valley',
        elementId: 'flora',
      ),
      _GoodNpc(
        id: 'bloomed_postea_scientist',
        nameIt: 'Scienziato Sbocciato',
        nameEn: 'Bloomed Scientist',
        descIt:
            'Ex Scienziato di Postea trasformato da Valley in un mostro pianta OP: futuro, carne e fiori non sono più separati.',
        descEn:
            'Former Postea Scientist transformed by Valley into an OP plant monster: future, flesh and flowers are no longer separate.',
        role: 'postea_bloom',
        elementId: 'flora',
      ),
      _GoodNpc(
        id: 'postea_elite_guard',
        nameIt: 'Guardia Élite di Postea',
        nameEn: 'Postea Elite Guard',
        descIt:
            'Soldato Élite sopravvissuto all evento Postea. Entra nel team con vita propria, scudo militare e granate difensive.',
        descEn:
            'Elite soldier who survived the Postea event. Joins the team with personal HP, military shield and defensive grenades.',
        role: 'postea_elite_guard',
        elementId: 'postea',
      ),

      _GoodNpc(
        id: 'kooba_glimmer_moralist',
        nameIt: 'Kooba degli Ingranaggi Scintillanti',
        nameEn: 'Kooba of Glimmering Gears',
        descIt:
            'Mostro pacifico simile a un jerboa dalle orecchie lunghe, con un cranio leggero sulla testa. Ha una morale fortissima: non ruba, raccoglie ciò che il dungeon ha già abbandonato.',
        descEn:
            'Peaceful jerboa-like monster with long ears and a small skull on its head. Strong moral code: it does not steal, it gathers what the dungeon already abandoned.',
        role: 'buffer',
        elementId: 'metal',
      ),

      _GoodNpc(
        id: 'mela_seedling',
        nameIt: 'Mela Verde Piccola',
        nameEn: 'Small Green Apple',
        descIt:
            'NPC debole del Piano 0: combatte per poche azioni, cura poco e poi torna tra le foglie.',
        descEn:
            'Weak Floor 0 NPC: fights for a few actions, heals lightly, then returns among the leaves.',
        role: 'healer',
        elementId: 'flora',
      ),
      _GoodNpc(
        id: 'lucciola_fredda',
        nameIt: 'Lucciola Fredda',
        nameEn: 'Cold Firefly',
        descIt:
            'NPC debole del Piano 0: combatte per poche azioni, dà critico e luce fredda.',
        descEn:
            'Weak Floor 0 NPC: fights for a few actions, gives critical and cold light.',
        role: 'buffer',
        elementId: 'ice',
      ),
      _GoodNpc(
        id: 'rana_di_sale',
        nameIt: 'Rana di Sale',
        nameEn: 'Salt Frog',
        descIt:
            'NPC debole del Piano 0: combatte per poche azioni, dà Scudo e può prendere il colpo.',
        descEn:
            'Weak Floor 0 NPC: fights for a few actions, gives Shield and may take the hit.',
        role: 'guard',
        elementId: 'water',
      ),

      _GoodNpc(
        id: 'rana_insalata',
        nameIt: 'Rana Insalata',
        nameEn: 'Salad Frog',
        descIt:
            'NPC debole del Piano 0: una rana verdissima e seria. Dona Resilienza per poche azioni, poi salta via offesa.',
        descEn:
            'Weak Floor 0 NPC: a very green and serious frog. Grants Resilience for a few actions, then hops away offended.',
        role: 'healer',
        elementId: 'flora',
      ),
      _GoodNpc(
        id: 'gufus_leviante',
        nameIt: 'Gufus Leviante il Grande Eroe',
        nameEn: 'Gufus Leviante the Great Hero',
        descIt:
            'NPC impegnato del Piano 0: una dolce civetta bianca alta fino al ginocchio, avvolta in un mantello nero con cappuccio e armata di un piccolo coltellino. Ha voluto così tanto mascherare la sua vera natura e imitare gli umani da mutare il proprio corpo con la sola Volontà. Solo quando cede del tutto emerge la Bestia: un’enorme civetta in decadimento con acido che cola dalla bocca e occhi bianchi vitrei.',
        descEn:
            'Busy Floor 0 NPC: a gentle white owl only as tall as your knee, wrapped in a black hooded cloak and armed with a small knife. It wanted so badly to mask its true nature and imitate humans that it reshaped its body through Will alone. Only when it fully gives in does the Beast emerge: a huge decaying owl with acid dripping from its beak and milky white eyes.',
        role: 'buffer',
        elementId: 'shadow',
      ),
      _GoodNpc(
        id: 'arcane_duelist_mira',
        nameIt: 'Mira, Duellante Arcana',
        nameEn: 'Mira, Arcane Duelist',
        descIt:
            'NPC da run: entra con scatti brevi, colpisce il bersaglio più debole e aumenta il critico.',
        descEn:
            'Run NPC: enters with short dashes, hits the weakest target and increases critical.',
        role: 'striker',
        elementId: 'lightning',
      ),
      _GoodNpc(
        id: 'frost_ring_apprentice',
        nameIt: 'Apprendista degli Anelli di Gelo',
        nameEn: 'Frost Ring Apprentice',
        descIt:
            'NPC da run: piazza piccoli cerchi di gelo, aggiunge Scudo e indebolisce i nemici.',
        descEn:
            'Run NPC: places small frost rings, adds Shield and weakens enemies.',
        role: 'guard',
        elementId: 'ice',
      ),
      _GoodNpc(
        id: 'ember_orbit_piper',
        nameIt: 'Pifferaio dell Orbita di Brace',
        nameEn: 'Ember Orbit Piper',
        descIt:
            'NPC da run: fa girare braci intorno al party e aumenta danno e bruciatura.',
        descEn:
            'Run NPC: spins embers around the party and increases damage and burn.',
        role: 'buffer',
        elementId: 'fire',
      ),
      _GoodNpc(
        id: 'tidal_seal_mender',
        nameIt: 'Ricucitrice del Sigillo di Marea',
        nameEn: 'Tidal Seal Mender',
        descIt:
            'NPC da run: cura, stabilizza e rende più sicuri gli incontri con gruppi.',
        descEn: 'Run NPC: heals, stabilizes and makes group fights safer.',
        role: 'healer',
        elementId: 'water',
      ),

      _GoodNpc(
        id: 'affogato_temporaneo',
        nameIt: 'Affogato Temporaneo',
        nameEn: 'Temporary Drowned',
        descIt:
            'Creatura tenuta viva per tre turni dalla necromanzia acquatica. Ricorda poco, ma attacca ancora.',
        descEn:
            'Creature kept alive for three turns by aquatic necromancy. It remembers little, but still attacks.',
        role: 'striker',
        elementId: 'water',
      ),
      _GoodNpc(
        id: 'affogato_temporaneo_2',
        nameIt: 'Secondo Affogato',
        nameEn: 'Second Drowned',
        descIt:
            'Secondo corpo d’acqua e ricordi spezzati. Resta finché il richiamo non si chiude.',
        descEn:
            'Second body of water and broken memories. It remains until the call closes.',
        role: 'striker',
        elementId: 'water',
      ),
      _GoodNpc(
        id: 'affogato_temporaneo_3',
        nameIt: 'Terzo Affogato',
        nameEn: 'Third Drowned',
        descIt: 'Terzo affogato: il mare lo tira per i nervi e lui obbedisce.',
        descEn: 'Third drowned: the sea pulls it by the nerves and it obeys.',
        role: 'striker',
        elementId: 'water',
      ),
      _GoodNpc(
        id: 'affogato_temporaneo_4',
        nameIt: 'Quarto Affogato del Romanzo',
        nameEn: 'Fourth Novel Drowned',
        descIt:
            'Il Romanzo tiene aperto un ricordo in più: un quarto affogato resta per poco.',
        descEn:
            'The Novel keeps one extra memory open: a fourth drowned remains briefly.',
        role: 'striker',
        elementId: 'water',
      ),
    ];
  }

  List<_AchievementDef> _generateAchievements() {
    return const [
      _AchievementDef(
        id: 'postea_coin',
        titleIt: 'Moneta di Postea',
        titleEn: 'Postea Coin',
        descIt: 'Inizia l evento Rapimento di Gufus Leviante.',
        descEn: 'Start the Gufus Leviante Kidnapping event.',
        rewardIt: 'Evento speciale rivelato',
        rewardEn: 'Special event revealed',
        rewardType: 'none',
        rewardId: 'postea_coin',
        hidden: true,
      ),
      _AchievementDef(
        id: 'postea_scientist_unlocked',
        titleIt: 'Il Futuro ha Rapito un Amico',
        titleEn: 'The Future Kidnapped a Friend',
        descIt: 'Sblocca lo scontro contro lo Scienziato di Postea.',
        descEn: 'Unlock the fight against the Postea Scientist.',
        rewardIt: 'Boss evento: Scienziato di Postea',
        rewardEn: 'Event boss: Postea Scientist',
        rewardType: 'none',
        rewardId: 'postea_scientist',
        hidden: true,
      ),
      _AchievementDef(
        id: 'postea_gufus_rescue',
        titleIt: 'Rapimento di Gufus Leviante',
        titleEn: 'Gufus Leviante Kidnapping',
        descIt: 'Completa l evento Postea e salva Gufus Leviante.',
        descEn: 'Complete the Postea event and rescue Gufus Leviante.',
        rewardIt: 'Set Elite di Postea',
        rewardEn: 'Postea Elite Set',
        rewardType: 'none',
        rewardId: 'postea_elite_set',
        hidden: true,
      ),
      _AchievementDef(
        id: 'postea_valley_smile',
        titleIt: 'Sorriso di Valley',
        titleEn: 'Valley Smile',
        descIt:
            'Ottieni l esito rarissimo in cui Valley fa sbocciare lo Scienziato potenziato.',
        descEn:
            'Obtain the ultra-rare outcome where Valley blooms the enhanced Scientist.',
        rewardIt: 'NPC: Scienziato Sbocciato',
        rewardEn: 'NPC: Bloomed Scientist',
        rewardType: 'npc',
        rewardId: 'bloomed_postea_scientist',
        hidden: true,
      ),
      _AchievementDef(
        id: 'postea_leviante_genes',
        titleIt: 'Geni Leviante',
        titleEn: 'Leviante Genes',
        descIt:
            'Sconfiggi lo Scienziato dopo il potenziamento con i geni di Gufus.',
        descEn: 'Defeat the Scientist after the enhancement with Gufus genes.',
        rewardIt: 'Memoria di Postea registrata',
        rewardEn: 'Memory of Postea recorded',
        rewardType: 'none',
        rewardId: 'postea_genes',
        hidden: true,
      ),
      _AchievementDef(
        id: 'peaceful_monsters_kooba',
        titleIt: 'Morale Piccola, Cranio Leggero',
        titleEn: 'Small Morals, Light Skull',
        descIt:
            'Incontra i mostri pacifici: Kooba, kitty slime e piccoli oggetti scintillanti.',
        descEn:
            'Meet the peaceful monsters: Kooba, kitty slimes and small glimmering objects.',
        rewardIt: 'NPC: Kooba degli Ingranaggi Scintillanti',
        rewardEn: 'NPC: Kooba of Glimmering Gears',
        rewardType: 'npc',
        rewardId: 'kooba_glimmer_moralist',
        hidden: true,
      ),
      _AchievementDef(
        id: 'baghest_eye_relic_unlocked',
        titleIt: 'L’Occhio che non Vuole Baghest',
        titleEn: 'The Eye that Refuses Baghest',
        descIt:
            'Sconfiggi Eiva Baghest: da ora il suo occhio può apparire nelle reliquie iniziali.',
        descEn:
            'Defeat Eiva Baghest: from now on its eye can appear among starting relics.',
        rewardIt: 'Reliquia: Occhio di Baghest',
        rewardEn: 'Relic: Baghest Eye',
        rewardType: 'relic',
        rewardId: 'occhio_baghest',
        hidden: true,
      ),
      _AchievementDef(
        id: 'skull_hands_relic_unlocked',
        titleIt: 'Due Mani al Posto del Coraggio',
        titleEn: 'Two Hands Instead of Courage',
        descIt: 'Raggiungi il piano 6 senza il Taverniere nel party.',
        descEn: 'Reach floor 6 without the Tavernkeeper in the party.',
        rewardIt: 'Reliquia: Mani del Teschio',
        rewardEn: 'Relic: Skull Hands',
        rewardType: 'relic',
        rewardId: 'mani_teschio',
        hidden: true,
      ),
      _AchievementDef(
        id: 'pawn_relic_unlocked',
        titleIt: 'Qualcuno Prende il Colpo',
        titleEn: 'Someone Takes the Hit',
        descIt: 'Raggiungi il piano 3 con almeno 50 Scudo.',
        descEn: 'Reach floor 3 with at least 50 Shield.',
        rewardIt: 'Reliquia: Pawn',
        rewardEn: 'Relic: Pawn',
        rewardType: 'relic',
        rewardId: 'pawn_guardiano',
        hidden: true,
      ),
      _AchievementDef(
        id: 'rebirth_seed_relic_unlocked',
        titleIt: 'Il Seme non Vuole Finire',
        titleEn: 'The Seed Refuses to End',
        descIt:
            'Raggiungi il piano 3: il dungeon inizia a concedere rinascite rare.',
        descEn: 'Reach floor 3: the dungeon begins granting rare rebirths.',
        rewardIt: 'Reliquia: Seme di Rinascita',
        rewardEn: 'Relic: Rebirth Seed',
        rewardType: 'relic',
        rewardId: 'seme_rinascita',
        hidden: true,
      ),
      _AchievementDef(
        id: 'hoshy_relic_unlocked',
        titleIt: 'Graffi sul Silenzio',
        titleEn: 'Scratches on Silence',
        descIt:
            'Usa 5 attacchi ad area o tecniche Art: i graffi sonici iniziano a rispondere.',
        descEn:
            'Use 5 AoE attacks or Art techniques: the sonic scratches begin to answer.',
        rewardIt: 'Reliquia: Graffi Sonici di Hoshy + Oculum Art Hoshy',
        rewardEn: 'Relic: Hoshy Sonic Scratches + Hoshy Oculum Art',
        rewardType: 'relic',
        rewardId: 'graffi_sonici_hoshy',
        hidden: true,
      ),
      _AchievementDef(
        id: 'vervain_relic_unlocked',
        titleIt: 'Fiori con Denti sotto Pelle',
        titleEn: 'Flowers with Teeth Under Skin',
        descIt:
            'Completa 3 eventi Titolo o natura: i vermi decadenti imparano il tuo odore.',
        descEn:
            'Complete 3 Title or nature events: the decaying worms learn your scent.',
        rewardIt: 'Reliquia: Vermi Decadenti di Vervain',
        rewardEn: 'Relic: Vervain Decaying Worms',
        rewardType: 'relic',
        rewardId: 'vermi_decadenti_vervain',
        hidden: true,
      ),
      _AchievementDef(
        id: 'baghest_costume_unlocked',
        titleIt: 'Sotto il Mantello di Baghest',
        titleEn: 'Under Baghest’s Mantle',
        descIt: 'Sconfiggi Eiva Baghest e sopravvivi alla sua corruzione.',
        descEn: 'Defeat Eiva Baghest and survive its corruption.',
        rewardIt: 'Costume: Cultista di Baghest',
        rewardEn: 'Costume: Baghest Cultist',
        rewardType: 'costume',
        rewardId: 'baghest_cultist_armor',
        hidden: true,
      ),
      _AchievementDef(
        id: 'oculian_costume_unlocked',
        titleIt: 'Tre Mantelli Pieni d’Occhi',
        titleEn: 'Three Mantles Full of Eyes',
        descIt:
            'Uccidi 3 Oculiani e impara a cucire il loro mantello senza farti guardare.',
        descEn:
            'Kill 3 Oculians and learn to sew their mantle without being watched.',
        rewardIt: 'Costume: Mantello dell’Oculiano',
        rewardEn: 'Costume: Oculian Eye Mantle',
        rewardType: 'costume',
        rewardId: 'oculian_eye_mantle',
        hidden: true,
      ),
      _AchievementDef(
        id: 'vitalium_costume_unlocked',
        titleIt: 'La Cura ha Fame',
        titleEn: 'Healing is Hungry',
        descIt:
            'Usa 5 Vitalium e lascia che il dungeon capisca che preferisci carne a scudo.',
        descEn:
            'Use 5 Vitalium and let the dungeon understand you prefer flesh over shield.',
        rewardIt: 'Costume: Veste di Vitalium Ridefinito',
        rewardEn: 'Costume: Refined Vitalium Gown',
        rewardType: 'costume',
        rewardId: 'vitalium_rebirth_gown',
        hidden: true,
      ),
      _AchievementDef(
        id: 'evonest_costume_unlocked',
        titleIt: 'Leoness Ti Calma',
        titleEn: 'Leoness Calms You',
        descIt: 'Ottieni una prova per Evonest nel suo tempio.',
        descEn: 'Gain proof for Evonest inside its temple.',
        rewardIt: 'Costume: Carapace delle Tre Teste',
        rewardEn: 'Costume: Three-Head Shell',
        rewardType: 'costume',
        rewardId: 'evonest_triple_shell',
        hidden: true,
      ),
      _AchievementDef(
        id: 'asher_costume_unlocked',
        titleIt: 'Firma sulla Brace',
        titleEn: 'Signature on Ember',
        descIt: 'Accetta un contratto del Fuoco di Asher.',
        descEn: 'Accept a contract from Asher’s Fire.',
        rewardIt: 'Costume: Giacca del Contratto di Asher',
        rewardEn: 'Costume: Asher Contract Jacket',
        rewardType: 'costume',
        rewardId: 'asher_burnt_contract',
        hidden: true,
      ),
      _AchievementDef(
        id: 'drowned_costume_unlocked',
        titleIt: 'Monete sotto l’Acqua',
        titleEn: 'Coins Underwater',
        descIt: 'Visita la città di commercio degli affogati.',
        descEn: 'Visit the drowned trade city.',
        rewardIt: 'Costume: Tunica degli Affogati',
        rewardEn: 'Costume: Drowned Trade Robe',
        rewardType: 'costume',
        rewardId: 'drowned_city_robe',
        hidden: true,
      ),
      _AchievementDef(
        id: 'hidenas_costume_unlocked',
        titleIt: 'Ignifugo non Vuol Dire Salvo',
        titleEn: 'Fireproof Does Not Mean Safe',
        descIt: 'Stringi un’alleanza con gli Hideani.',
        descEn: 'Make an alliance with the Hideans.',
        rewardIt: 'Costume: Uniforme Hideana',
        rewardEn: 'Costume: Hidean Uniform',
        rewardType: 'costume',
        rewardId: 'hidenas_thousand_ember_uniform',
        hidden: true,
      ),
      _AchievementDef(
        id: 'vapium_costume_unlocked',
        titleIt: 'Nebbia che Diventa Pietra',
        titleEn: 'Mist Becoming Stone',
        descIt: 'Raggiungi il piano 9 con almeno 80 Scudo.',
        descEn: 'Reach floor 9 with at least 80 Shield.',
        rewardIt: 'Costume: Corazza di Vapium Compresso',
        rewardEn: 'Costume: Compressed Vapium Plate',
        rewardType: 'costume',
        rewardId: 'vapium_vapor_plate',
        hidden: true,
      ),
      _AchievementDef(
        id: 'lunium_costume_unlocked',
        titleIt: 'La Luna Ricorda il Rosa',
        titleEn: 'The Moon Remembers Pink',
        descIt: 'Usa 10 Skill Oculum mentre porti un’Art lunare o stellare.',
        descEn: 'Use 10 Oculum Skills while carrying a moon or star Art.',
        rewardIt: 'Costume: Velo di Lunium',
        rewardEn: 'Costume: Lunium Veil',
        rewardType: 'costume',
        rewardId: 'moonhills_lunium_veil',
        hidden: true,
      ),
      _AchievementDef(
        id: 'obser_costume_unlocked',
        titleIt: 'Occhi nelle Tasche',
        titleEn: 'Eyes in the Pockets',
        descIt: 'Compra 5 volte dal mercante.',
        descEn: 'Buy 5 times from the merchant.',
        rewardIt: 'Costume: Giacca del Mercante di Obser',
        rewardEn: 'Costume: Obser Merchant Jacket',
        rewardType: 'costume',
        rewardId: 'obser_merchant_jacket',
        hidden: true,
      ),
      _AchievementDef(
        id: 'first_blood',
        titleIt: 'Primo Sangue sull’Occhio',
        titleEn: 'First Blood on the Eye',
        descIt: 'Sconfiggi il tuo primo nemico nel dungeon.',
        descEn: 'Defeat your first enemy in the dungeon.',
        rewardIt: 'NPC: Skelly, Oste delle Ossa',
        rewardEn: 'NPC: Skelly, Bone Innkeeper',
        rewardType: 'npc',
        rewardId: 'skelly_bone_innkeeper',
      ),
      _AchievementDef(
        id: 'win_multi_fight',
        titleIt: 'Tre Ombre, Un Respiro',
        titleEn: 'Three Shadows, One Breath',
        descIt: 'Vinci un fight contro più creature.',
        descEn: 'Win a fight against multiple creatures.',
        rewardIt: 'NPC: Esploratrice della Piuma Indaco',
        rewardEn: 'NPC: Indigo Feather Scout',
        rewardType: 'npc',
        rewardId: 'indigo_feather_scout',
      ),
      _AchievementDef(
        id: 'first_boss',
        titleIt: 'La Corona si Incrina',
        titleEn: 'The Crown Cracks',
        descIt: 'Sconfiggi un boss di piano.',
        descEn: 'Defeat a floor boss.',
        rewardIt: 'NPC: Scudiero di Vapium Muto',
        rewardEn: 'NPC: Mute Vapium Squire',
        rewardType: 'npc',
        rewardId: 'mute_vapium_squire',
      ),
      _AchievementDef(
        id: 'ten_oculum_skills',
        titleIt: 'Mano sul Cristallo Vivo',
        titleEn: 'Hand on the Living Crystal',
        descIt: 'Usa 10 Skill Oculum.',
        descEn: 'Use 10 Oculum Skills.',
        rewardIt: 'NPC: Bambina dell’Oculum Bendato',
        rewardEn: 'NPC: Blindfolded Oculum Girl',
        rewardType: 'npc',
        rewardId: 'blind_oculum_girl',
        hidden: true,
      ),
      _AchievementDef(
        id: 'aoe_master',
        titleIt: 'Il Cerchio Non Perdona',
        titleEn: 'The Circle Does Not Forgive',
        descIt: 'Usa 5 attacchi ad area.',
        descEn: 'Use 5 area attacks.',
        rewardIt: 'Arma: Chakram dell’Orbita Cieca',
        rewardEn: 'Weapon: Blind Orbit Chakram',
        rewardType: 'weapon',
        rewardId: 'blind_orbit_chakram',
      ),
      _AchievementDef(
        id: 'fetal_survivor',
        titleIt: 'Non Voltarti',
        titleEn: 'Do Not Turn Back',
        descIt: 'Sopravvivi a un inseguimento dell’Uomo in Posizione Fetale.',
        descEn: 'Survive a chase from the Man in Fetal Position.',
        rewardIt: 'Art casuale oscura',
        rewardEn: 'Random dark Art',
        rewardType: 'random_art',
        rewardId: 'shadow',
        hidden: true,
      ),
      _AchievementDef(
        id: 'floor_six',
        titleIt: 'Metà Palpebra',
        titleEn: 'Half Eyelid',
        descIt: 'Raggiungi il piano 6.',
        descEn: 'Reach floor 6.',
        rewardIt: 'NPC: Piccola Liturgista del Sole',
        rewardEn: 'NPC: Little Sun Liturgist',
        rewardType: 'npc',
        rewardId: 'little_sun_liturgist',
      ),
      _AchievementDef(
        id: 'drop_socketed',
        titleIt: 'Arma con una Lacrima Dentro',
        titleEn: 'Weapon with a Tear Inside',
        descIt: 'Incastona un drop unico nell’arma.',
        descEn: 'Socket a unique drop into the weapon.',
        rewardIt: 'NPC: Paggetto del Principe Slime',
        rewardEn: 'NPC: Prince Slime Page',
        rewardType: 'npc',
        rewardId: 'slime_prince_page',
      ),
      _AchievementDef(
        id: 'oculum_spento_20',
        titleIt: 'Fuoco Spento in Tasca',
        titleEn: 'Dead Fire in Your Pocket',
        descIt: 'Accumula 20 Oculum Spento.',
        descEn: 'Hold 20 Spent Oculum.',
        rewardIt: 'NPC: Portalanterna Senza Ombra',
        rewardEn: 'NPC: Shadowless Lampbearer',
        rewardType: 'npc',
        rewardId: 'shadowless_lampbearer',
        hidden: true,
      ),
      _AchievementDef(
        id: 'merchant_cards',
        titleIt: 'La Mano Sceglie la Carta',
        titleEn: 'The Hand Chooses the Card',
        descIt: 'Compra 5 oggetti dal mercante.',
        descEn: 'Buy 5 items from the merchant.',
        rewardIt: 'NPC: Scriba delle Carte di Cenere',
        rewardEn: 'NPC: Ashen Card Scribe',
        rewardType: 'npc',
        rewardId: 'ashen_card_scribe',
      ),

      _AchievementDef(
        id: 'potion_user',
        titleIt: 'Zaino Rapido',
        titleEn: 'Quick Bag',
        descIt: 'Usa 5 consumabili dallo zaino rapido.',
        descEn: 'Use 5 consumables from the quick bag.',
        rewardIt: 'NPC: Falena Speziale',
        rewardEn: 'NPC: Apothecary Moth',
        rewardType: 'npc',
        rewardId: 'apothecary_moth',
      ),
      _AchievementDef(
        id: 'drop_scholar',
        titleIt: 'Studio dei Drop',
        titleEn: 'Drop Study',
        descIt: 'Studia 5 drop nemici.',
        descEn: 'Study 5 enemy drops.',
        rewardIt: 'NPC: Cartografo d’Ossa',
        rewardEn: 'NPC: Bone Cartographer',
        rewardType: 'npc',
        rewardId: 'bone_cartographer',
      ),
      _AchievementDef(
        id: 'floor_nine',
        titleIt: 'Piano Nove',
        titleEn: 'Floor Nine',
        descIt: 'Raggiungi il piano 9.',
        descEn: 'Reach floor 9.',
        rewardIt: 'Arma: Ago Lunare',
        rewardEn: 'Weapon: Moon Needle',
        rewardType: 'weapon',
        rewardId: 'moon_needle',
      ),
      _AchievementDef(
        id: 'converted_drops',
        titleIt: 'Alchimia dei Drop',
        titleEn: 'Drop Alchemy',
        descIt: 'Converti 4 drop nemici in consumabili.',
        descEn: 'Convert 4 enemy drops into consumables.',
        rewardIt: 'NPC: Fabbro Slime',
        rewardEn: 'NPC: Slime Smith',
        rewardType: 'npc',
        rewardId: 'slime_smith',
      ),
      _AchievementDef(
        id: 'art_technique_user',
        titleIt: 'Tecnica Art',
        titleEn: 'Art Technique',
        descIt: 'Usa 6 tecniche uniche della tua Art.',
        descEn: 'Use 6 unique techniques of your Art.',
        rewardIt: 'NPC: Monaca Null',
        rewardEn: 'NPC: Null Nun',
        rewardType: 'npc',
        rewardId: 'null_nun',
        hidden: true,
      ),
      _AchievementDef(
        id: 'evonest_proof',
        titleIt: 'Prova per Evonest',
        titleEn: 'Proof for Evonest',
        descIt: 'Dimostra bontà nel tempio di Evonest.',
        descEn: 'Prove goodness inside Evonest temple.',
        rewardIt: 'Arma: Scaglia di Evonest',
        rewardEn: 'Weapon: Evonest Scale',
        rewardType: 'weapon',
        rewardId: 'evonest_three_head_scale',
      ),
      _AchievementDef(
        id: 'asher_contract',
        titleIt: 'Contratto di Asher',
        titleEn: 'Asher Contract',
        descIt: 'Accetta un contratto del Fuoco di Asher.',
        descEn: 'Accept an Asher Fire contract.',
        rewardIt: 'Art: Fuoco di Asher',
        rewardEn: 'Art: Asher Fire',
        rewardType: 'art',
        rewardId: 'asher_fire_art',
      ),
      _AchievementDef(
        id: 'drowned_magic',
        titleIt: 'Affogato Vivo',
        titleEn: 'Living Drowned',
        descIt: 'Usa una creatura affogata per tre turni.',
        descEn: 'Use a drowned creature for three turns.',
        rewardIt: 'Art: Necromanzia Acquatica',
        rewardEn: 'Art: Aquatic Necromancy',
        rewardType: 'art',
        rewardId: 'water_necromancy_art',
        hidden: true,
      ),
      _AchievementDef(
        id: 'tavern_sleep',
        titleIt: 'Dormire sotto il Cranio',
        titleEn: 'Sleep under the Skull',
        descIt: 'Dormi nella Taverna del Teschio Enorme.',
        descEn: 'Sleep inside the Giant Skull Tavern.',
        rewardIt: 'NPC: Il Taverniere del Teschio Enorme',
        rewardEn: 'NPC: The Giant Skull Tavernkeeper',
        rewardType: 'npc',
        rewardId: 'giant_skull_tavernkeeper',
        hidden: true,
      ),
      _AchievementDef(
        id: 'critical_shield_broken',
        titleIt: 'Scudo Spezzato dal Critico',
        titleEn: 'Shield Broken by Critical',
        descIt:
            'Fai spezzare lo Scudo Critico dopo aver diviso almeno un colpo.',
        descEn:
            'Break the Critical Shield after it has divided at least one hit.',
        rewardIt: 'Arma: Alabarda Null',
        rewardEn: 'Weapon: Null Halberd',
        rewardType: 'weapon',
        rewardId: 'null_halberd',
        hidden: true,
      ),
      _AchievementDef(
        id: 'saved_ally_strike',
        titleIt: 'La Mano che Ritorna',
        titleEn: 'The Hand that Returns',
        descIt:
            'L’alleato salvato interviene nel primo turno con il colpo critico.',
        descEn: 'The saved ally joins the first turn with the critical hit.',
        rewardIt: 'NPC: Duellante Arrugginito',
        rewardEn: 'NPC: Rusted Duelist',
        rewardType: 'npc',
        rewardId: 'rusted_duelist',
        hidden: true,
      ),
      _AchievementDef(
        id: 'mille_fuochi_unlocked',
        titleIt: 'Ultime Sedici Fiamme',
        titleEn: 'Last Sixteen Flames',
        descIt: 'Sblocca l’Emblem Art dei Mille Fuochi nelle ultime 16 stanze.',
        descEn: 'Unlock the Thousand Fires Emblem Art in the last 16 rooms.',
        rewardIt: 'Art: Emblem Art dei Mille Fuochi',
        rewardEn: 'Art: Thousand Fires Emblem Art',
        rewardType: 'art',
        rewardId: 'thousand_fires_emblem_art',
        hidden: true,
      ),
      _AchievementDef(
        id: 'mille_fuochi_used',
        titleIt: 'Il Finale Brucia',
        titleEn: 'The Ending Burns',
        descIt: 'Usa l’Emblem Art dei Mille Fuochi.',
        descEn: 'Use the Thousand Fires Emblem Art.',
        rewardIt: 'Arma: Marchio di Asher',
        rewardEn: 'Weapon: Asher Brand',
        rewardType: 'weapon',
        rewardId: 'asher_contract_brand',
        hidden: true,
      ),
      _AchievementDef(
        id: 'run_victory',
        titleIt: 'L’Occhio si Chiude Piano',
        titleEn: 'The Eye Closes Slowly',
        descIt: 'Completa l’intera run.',
        descEn: 'Clear the whole run.',
        rewardIt: 'Oculum Spento +20',
        rewardEn: 'Spent Oculum +20',
        rewardType: 'oculum',
        rewardId: '20',
        hidden: true,
      ),
      _AchievementDef(
        id: 'weapon_collector_10',
        titleIt: 'Dieci Ferri nell’Occhio',
        titleEn: 'Ten Irons in the Eye',
        descIt: 'Sblocca 10 armi iniziali.',
        descEn: 'Unlock 10 starting weapons.',
        rewardIt: 'Arma: Gadget Hideano',
        rewardEn: 'Weapon: Hidean Gadget',
        rewardType: 'weapon',
        rewardId: 'hidean_trade_gadget',
        hidden: true,
      ),
      _AchievementDef(
        id: 'art_collector_12',
        titleIt: 'Dodici Palpebre Aperte',
        titleEn: 'Twelve Open Eyelids',
        descIt: 'Sblocca 12 Art.',
        descEn: 'Unlock 12 Arts.',
        rewardIt: 'Art casuale',
        rewardEn: 'Random Art',
        rewardType: 'random_art',
        rewardId: 'any',
        hidden: true,
      ),
      _AchievementDef(
        id: 'floor_zero_clear',
        titleIt: 'Piano Zero',
        titleEn: 'Floor Zero',
        descIt: 'Completa le 7 stanze del Piano 0.',
        descEn: 'Complete the 7 rooms of Floor 0.',
        rewardIt: 'Titolo casuale',
        rewardEn: 'Random Title',
        rewardType: 'title',
        rewardId: 'random',
        hidden: false,
      ),
      _AchievementDef(
        id: 'minor_oculian_watcher',
        titleIt: 'Ti Osserva Soltanto',
        titleEn: 'It Only Watches You',
        descIt:
            'Al piano 3 incontra l’Oculiano Minore generato da un Punto Cieco di Titolo.',
        descEn:
            'On floor 3 meet the Minor Oculian generated by a Title Blind Spot.',
        rewardIt: 'NPC: Oculiano Minore',
        rewardEn: 'NPC: Minor Oculian',
        rewardType: 'npc',
        rewardId: 'minor_oculian_watcher',
        hidden: true,
      ),
      _AchievementDef(
        id: 'thousand_eyes_child',
        titleIt: 'Troppe Lacrime per un Bambino',
        titleEn: 'Too Many Tears for a Child',
        descIt: 'Al piano 6 trova il Bambino dai Mille Occhi.',
        descEn: 'On floor 6 find the Thousand-Eyed Child.',
        rewardIt: 'NPC: Bambino dai Mille Occhi',
        rewardEn: 'NPC: Thousand-Eyed Child',
        rewardType: 'npc',
        rewardId: 'thousand_eyes_child',
        hidden: true,
      ),
      _AchievementDef(
        id: 'title_whisper_three',
        titleIt: 'Tre Sussurri dei Titoli',
        titleEn: 'Three Title Whispers',
        descIt: 'Attiva 3 eventi positivi/neutri generati dai Titoli.',
        descEn: 'Trigger 3 positive/neutral events generated by Titles.',
        rewardIt: 'Titolo casuale',
        rewardEn: 'Random Title',
        rewardType: 'title',
        rewardId: 'random',
        hidden: true,
      ),
      _AchievementDef(
        id: 'blind_spot_seen',
        titleIt: 'Il Punto Cieco ha Denti',
        titleEn: 'The Blind Spot Has Teeth',
        descIt: 'Attiva un evento di Punto Cieco da Titolo.',
        descEn: 'Trigger a Title Blind Spot event.',
        rewardIt: 'Reliquia: Acqua Senza Gola',
        rewardEn: 'Relic: Throatless Water',
        rewardType: 'relic',
        rewardId: 'acqua_senza_gola',
        hidden: true,
      ),
      _AchievementDef(
        id: 'title_collector_10',
        titleIt: 'Dieci Nomi Appesi',
        titleEn: 'Ten Hanging Names',
        descIt: 'Sblocca 10 Titoli.',
        descEn: 'Unlock 10 Titles.',
        rewardIt: 'Titolo casuale',
        rewardEn: 'Random Title',
        rewardType: 'title',
        rewardId: 'random',
        hidden: true,
      ),

      _AchievementDef(
        id: 'oculum_expert',
        titleIt: 'Esperto di Oculum',
        titleEn: 'Oculum Expert',
        descIt:
            'Completa il piano 12 e porta Principiante alla sua forma finale.',
        descEn: 'Complete floor 12 and bring Beginner to its final form.',
        rewardIt: '36 Art uniche, nuove armi, Titoli, reliquie ed eventi',
        rewardEn: '36 unique Arts, new weapons, Titles, relics and events',
        rewardType: 'oculum',
        rewardId: '0',
        hidden: true,
      ),
      _AchievementDef(
        id: 'title_level_xii',
        titleIt: 'Dodici Nomi sullo stesso Occhio',
        titleEn: 'Twelve Names on the Same Eye',
        descIt: 'Porta un Titolo al livello XII.',
        descEn: 'Raise a Title to level XII.',
        rewardIt: 'Reliquia: Vento Sotto Unghia',
        rewardEn: 'Relic: Wind Under Nail',
        rewardType: 'relic',
        rewardId: 'vento_sotto_unghia',
        hidden: true,
      ),
      _AchievementDef(
        id: 'floor_three_title',
        titleIt: 'Terza Palpebra',
        titleEn: 'Third Eyelid',
        descIt: 'Arriva al piano 3 e sblocca uno slot Titolo aggiuntivo.',
        descEn: 'Reach floor 3 and unlock an extra Title slot.',
        rewardIt: 'Reliquia: Nido di Muschio',
        rewardEn: 'Relic: Moss Nest',
        rewardType: 'relic',
        rewardId: 'nido_di_muschio',
        hidden: true,
      ),
      _AchievementDef(
        id: 'floor_six_oculian',
        titleIt: 'Sesto Occhio Sporco',
        titleEn: 'Sixth Dirty Eye',
        descIt: 'Arriva al piano 6: gli Oculiani iniziano a cercarti.',
        descEn: 'Reach floor 6: Oculians start seeking you.',
        rewardIt: 'Reliquia: Stella Spina',
        rewardEn: 'Relic: Thorn Star',
        rewardType: 'relic',
        rewardId: 'stella_spina',
        hidden: true,
      ),
      _AchievementDef(
        id: 'floor_nine_moon',
        titleIt: 'Nona Luna Bassa',
        titleEn: 'Ninth Low Moon',
        descIt: 'Arriva al piano 9.',
        descEn: 'Reach floor 9.',
        rewardIt: 'Reliquia: Luna Lattea',
        rewardEn: 'Relic: Milky Moon',
        rewardType: 'relic',
        rewardId: 'luna_lattea',
        hidden: true,
      ),
      _AchievementDef(
        id: 'floor_twelve_end',
        titleIt: 'Dodicesimo Fondo',
        titleEn: 'Twelfth Depth',
        descIt: 'Arriva al piano 12.',
        descEn: 'Reach floor 12.',
        rewardIt: 'Reliquia: Vaso dei Morti Piccoli',
        rewardEn: 'Relic: Jar of Small Dead',
        rewardType: 'relic',
        rewardId: 'vaso_dei_morti_piccoli',
        hidden: true,
      ),
      _AchievementDef(
        id: 'novice_gate',
        titleIt: 'Novizio',
        titleEn: 'Novice',
        descIt: 'Completa la prova iniziale da 12 stanze, vinta o persa.',
        descEn: 'Complete the initial 12-room trial, win or lose.',
        rewardIt: '3 armi casuali e 3 Art casuali',
        rewardEn: '3 random weapons and 3 random Arts',
        rewardType: 'oculum',
        rewardId: '0',
        hidden: true,
      ),
      _AchievementDef(
        id: 'three_oculians',
        titleIt: 'Tre Mantelli di Occhi',
        titleEn: 'Three Eye-Mantles',
        descIt: 'Dal piano 6 in poi uccidi 3 Oculiani.',
        descEn: 'From floor 6 onward, kill 3 Oculians.',
        rewardIt: 'Reliquia: Costume da Oculiano',
        rewardEn: 'Relic: Oculian Costume',
        rewardType: 'relic',
        rewardId: 'costume_oculiano',
        hidden: true,
      ),
      _AchievementDef(
        id: 'party_two',
        titleIt: 'Piccolo Party Sporco',
        titleEn: 'Small Dirty Party',
        descIt: 'Porta due alleati buoni contemporaneamente.',
        descEn: 'Bring two good allies at the same time.',
        rewardIt: 'NPC: Falena Speziale',
        rewardEn: 'NPC: Apothecary Moth',
        rewardType: 'npc',
        rewardId: 'apothecary_moth',
        hidden: true,
      ),
    ];
  }

  _ElementDef elementDef(String id) {
    return _elements.firstWhere(
      (e) => e.id == id,
      orElse: () => _elements.first,
    );
  }

  Color elementColor(String id) => elementDef(id).color;

  String elementName(String id) {
    final e = elementDef(id);
    return t(e.nameIt, e.nameEn);
  }

  int get levelGradeCombatBonus =>
      max(0, widget.playerLevel) + max(0, widget.playerGrade) * 6;

  int get activeRelicRollBonus => cipoSerpentHp > 0 ? 5 : 0;
  int get totalVc =>
      widget.playerVc + dungeonVolonta ~/ 3 + activeRelicRollBonus;
  int get totalCm =>
      widget.playerCm + dungeonMateria ~/ 2 + activeRelicRollBonus;
  int get totalInitiative =>
      widget.playerInitiative + dungeonMateria ~/ 5 + activeRelicRollBonus;
  int get willMateriaDefense => (dungeonVolonta + dungeonMateria) ~/ 2;
  int get oculumArtPower => totalOculum * 2;
  String get posteaRunicMetalLabel {
    return '$posteaRunicMetalKg kg';
  }

  String principianteNameIt(int level) {
    const names = [
      'Principiante',
      'Iniziato dell’Occhio',
      'Portatore di Palpebra',
      'Allievo dell’Oculum',
      'Custode del Primo Sguardo',
      'Occhio che Impara',
      'Sopravvissuto dell’Oculum',
      'Discepolo delle Dodici Stanze',
      'Vedente della Corona Cieca',
      'Mano del Fato Oculare',
      'Araldo della Palpebra Finale',
      'Esperto di Oculum',
    ];
    return names[(level.clamp(1, 12).toInt()) - 1];
  }

  String principianteNameEn(int level) {
    const names = [
      'Beginner',
      'Eye Initiate',
      'Eyelid Bearer',
      'Oculum Apprentice',
      'Keeper of the First Gaze',
      'Eye that Learns',
      'Oculum Survivor',
      'Disciple of the Twelve Rooms',
      'Seer of the Blind Crown',
      'Hand of Ocular Fate',
      'Herald of the Final Eyelid',
      'Oculum Expert',
    ];
    return names[(level.clamp(1, 12).toInt()) - 1];
  }

  String titleNameIt(_TitleDef title) {
    if (title.id == 'principiante') {
      return principianteNameIt(titleLevel(title.id));
    }
    return title.nameIt;
  }

  String titleNameEn(_TitleDef title) {
    if (title.id == 'principiante') {
      return principianteNameEn(titleLevel(title.id));
    }
    return title.nameEn;
  }

  int titleLevel(String id) => titleLevels[id] ?? 1;

  Iterable<_TitleDef> get equippedTitles =>
      _allTitles.where((title) => equippedTitleIds.contains(title.id));

  int get baseRandomTitleSlots => 6;

  List<_TitleDef> availableRandomRunTitles() {
    final titles = _allTitles
        .where((title) => title.id != 'principiante')
        .where((title) => unlockedTitleIds.contains(title.id))
        .where((title) => !equippedTitleIds.contains(title.id))
        .toList();

    titles.shuffle(_random);
    return titles;
  }

  List<_TitleDef> threeRandomTitleChoices() {
    return availableRandomRunTitles().take(3).toList();
  }

  void showRunTitleDraft({
    required int targetSlots,
    required String reasonIt,
    required String reasonEn,
    bool startAfterComplete = false,
  }) {
    clearChoices(mode: 'titles');

    final target = targetSlots.clamp(1, titleSlotLimit).toInt();

    if (equippedTitleIds.length >= target ||
        availableRandomRunTitles().isEmpty) {
      if (startAfterComplete) {
        completeStartingTitleDraft();
      } else {
        textIt =
            '$reasonIt\n\n'
            'Nessun Titolo disponibile nel pool oppure slot già pieni.\n'
            'Titoli attivi: ${equippedTitles.map((t) => '${titleNameIt(t)} Lv.${titleLevel(t.id)}').join(', ')}';
        textEn =
            '$reasonEn\n\n'
            'No Title available in the pool or slots already full.\n'
            'Active Titles: ${equippedTitles.map((t) => '${titleNameEn(t)} Lv.${titleLevel(t.id)}').join(', ')}';
      }
      return;
    }

    final remaining = target - equippedTitleIds.length;
    final choices = threeRandomTitleChoices();

    textIt =
        '$reasonIt\n\n'
        'Scegli 1 Titolo fra 3.\n'
        'Scelte rimaste per questo blocco: $remaining.\n'
        'Pool valido: tutti i Titoli sbloccati, anche da achievement ottenuti in questa stessa run.';
    textEn =
        '$reasonEn\n\n'
        'Choose 1 Title among 3.\n'
        'Choices left for this block: $remaining.\n'
        'Valid pool: every unlocked Title, including achievements unlocked in this same run.';

    for (final title in choices) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: '${titleNameIt(title)} Lv.${titleLevel(title.id)}',
          labelEn: '${titleNameEn(title)} Lv.${titleLevel(title.id)}',
          icon: title.strong ? Icons.workspace_premium : Icons.style,
          color: title.strong ? Colors.amber : widget.tertiaryColor,
          onPressed: () => chooseRunTitle(
            title,
            targetSlots: target,
            reasonIt: reasonIt,
            reasonEn: reasonEn,
            startAfterComplete: startAfterComplete,
          ),
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Dettagli: ${titleNameIt(title)}',
          labelEn: 'Details: ${titleNameEn(title)}',
          icon: Icons.info_outline,
          color: Colors.blueGrey,
          onPressed: () {
            setState(() {
              textIt = titleDetailIt(title);
              textEn = titleDetailEn(title);
            });
          },
        ),
      );
    }
  }

  void chooseRunTitle(
    _TitleDef title, {
    required int targetSlots,
    required String reasonIt,
    required String reasonEn,
    required bool startAfterComplete,
  }) {
    setState(() {
      if (equippedTitleIds.contains(title.id)) {
        showRunTitleDraft(
          targetSlots: targetSlots,
          reasonIt: reasonIt,
          reasonEn: reasonEn,
          startAfterComplete: startAfterComplete,
        );
        return;
      }

      equippedTitleIds.add(title.id);
      applySingleTitleRunBonus(title);

      if (equippedTitleIds.length >= targetSlots ||
          availableRandomRunTitles().isEmpty) {
        clearChoices();

        if (startAfterComplete) {
          completeStartingTitleDraft();
          textIt =
              'Titolo scelto: ${titleNameIt(title)} Lv.${titleLevel(title.id)}\n\n'
              '${titleDetailIt(title)}\n\n'
              '$textIt';
          textEn =
              'Title chosen: ${titleNameEn(title)} Lv.${titleLevel(title.id)}\n\n'
              '${titleDetailEn(title)}\n\n'
              '$textEn';
        } else {
          textIt =
              'Titolo scelto: ${titleNameIt(title)} Lv.${titleLevel(title.id)}\n\n'
              '${titleDetailIt(title)}\n\n'
              'Titoli attivi: ${equippedTitles.map((t) => '${titleNameIt(t)} Lv.${titleLevel(t.id)}').join(', ')}';
          textEn =
              'Title chosen: ${titleNameEn(title)} Lv.${titleLevel(title.id)}\n\n'
              '${titleDetailEn(title)}\n\n'
              'Active Titles: ${equippedTitles.map((t) => '${titleNameEn(t)} Lv.${titleLevel(t.id)}').join(', ')}';
        }
        return;
      }

      showRunTitleDraft(
        targetSlots: targetSlots,
        reasonIt:
            'Titolo scelto: ${titleNameIt(title)} Lv.${titleLevel(title.id)}.\n'
            'Il dungeon ti offre un’altra scelta.',
        reasonEn:
            'Title chosen: ${titleNameEn(title)} Lv.${titleLevel(title.id)}.\n'
            'The dungeon offers another choice.',
        startAfterComplete: startAfterComplete,
      );
    });
  }

  void completeStartingTitleDraft() {
    applyEquippedTitleStartBonuses();
    generateNextSkillQuest();
    runActive = true;

    textIt =
        'La run comincia davvero.\n\n'
        'Titoli attivi: ${equippedTitles.map((t) => '${titleNameIt(t)} Lv.${titleLevel(t.id)}').join(', ')}\n\n'
        'Missione:\n$activeQuestIt\n\n'
        'Quest Skill:\n$activeSkillQuestIt';
    textEn =
        'The run truly begins.\n\n'
        'Active Titles: ${equippedTitles.map((t) => '${titleNameEn(t)} Lv.${titleLevel(t.id)}').join(', ')}\n\n'
        'Quest:\n$activeQuestEn\n\n'
        'Skill Quest:\n$activeSkillQuestEn';
  }

  bool maybeAwardFloorRandomTitle() {
    if (!runActive || gameOver || inCombat) return false;
    if (room <= 0 || room % 2 != 0) return false;
    if (titleChoiceRoomsClaimed.contains(room)) return false;

    titleChoiceRoomsClaimed.add(room);

    final before = equippedTitleIds.length;
    final target = before + 1;

    if (before >= titleSlotLimit) return false;

    if (availableRandomRunTitles().isEmpty) {
      addLog(
        t(
          'Stanza $room: nessun Titolo disponibile nel pool.',
          'Room $room: no Title available in the pool.',
        ),
      );
      return false;
    }

    showRunTitleDraft(
      targetSlots: target,
      reasonIt:
          'Stanza $room.\n\n'
          'Un Titolo può agganciarsi alla run.\n'
          'Scegline uno fra tre.',
      reasonEn:
          'Room $room.\n\n'
          'A Title can attach to the run.\n'
          'Choose one among three.',
    );
    return true;
  }

  void applySingleTitleRunBonus(_TitleDef title) {
    if (title.id == 'pelle_di_muschio') {
      runHealOnExplore += titleLevel(title.id);
    }

    if (title.id == 'ombra_che_ascolta') {
      runLifesteal += 1;
    }

    if (title.id == 'eco_del_fiore') {
      runHealOnExplore += 2;
    }

    if (title.id == 'giardino_nel_torace') {
      runHealOnExplore += 1;
    }

    if (title.id == 'coro_sottopelle') {
      runCritBonus += 3;
    }
  }

  int get titleSlotLimit => (1 + room ~/ 2).clamp(1, 18).toInt();

  int titleScaled(String id, int value) {
    if (value == 0) return 0;
    final lvl = titleLevel(id).clamp(1, 12).toInt();
    return value * lvl;
  }

  int get titleResBonus => equippedTitles.fold(
    0,
    (sum, title) => sum + titleScaled(title.id, title.res),
  );
  int get titleVolBonus => equippedTitles.fold(
    0,
    (sum, title) => sum + titleScaled(title.id, title.vol),
  );
  int get titleMatBonus => equippedTitles.fold(
    0,
    (sum, title) => sum + titleScaled(title.id, title.mat),
  );
  int get titleOcuBonus => equippedTitles.fold(
    0,
    (sum, title) => sum + titleScaled(title.id, title.ocu),
  );
  int get titleDamageBonus => equippedTitles.fold(
    0,
    (sum, title) => sum + titleScaled(title.id, title.damage),
  );
  int get titleDefenseBonus => equippedTitles.fold(
    0,
    (sum, title) => sum + titleScaled(title.id, title.defense),
  );

  List<_EquipmentSetDef> get activeEquipmentSets => _equipmentSets
      .where((set) => set.matches(starterWeapon, activeCostume))
      .toList();

  int get setDamageBonus =>
      activeEquipmentSets.fold(0, (sum, set) => sum + set.damageBonus);
  int get setDefenseBonus =>
      activeEquipmentSets.fold(0, (sum, set) => sum + set.defenseBonus);
  int get setShieldBonus =>
      activeEquipmentSets.fold(0, (sum, set) => sum + set.shieldBonus);
  int get setOculumBonus =>
      activeEquipmentSets.fold(0, (sum, set) => sum + set.oculumBonus);
  int get setCritBonus =>
      activeEquipmentSets.fold(0, (sum, set) => sum + set.critBonus);
  int get setVictoryChanceBonus =>
      activeEquipmentSets.fold(0, (sum, set) => sum + set.victoryChanceBonus);

  int get totalOculum =>
      dungeonOculum +
      titleOcuBonus +
      artOculumBonus() +
      setOculumBonus +
      (starterWeapon?.oculumBonus ?? 0);

  bool isExpertOnlyArtId(String id) => id.startsWith('expert_oculum_art_');

  bool get hasOculumExpertPack =>
      completedAchievementIds.contains('oculum_expert');

  bool isLateGameOnlyArtId(String id) => id == 'thousand_fires_emblem_art';

  bool isVillageLockedArtId(String id) => id == 'swiftness_martial_art';

  bool isArtUnlockableOutsideLateGame(_DungeonArt art) =>
      !isLateGameOnlyArtId(art.effectId) &&
      !isVillageLockedArtId(art.effectId) &&
      (!isExpertOnlyArtId(art.effectId) || hasOculumExpertPack) &&
      !(runCount <= 1 && art.effectId == 'thousand_fires_emblem_art');

  bool get hasNoviceAchievement =>
      completedAchievementIds.contains('novice_gate');

  int get maxActiveAllies =>
      3 + (activeRelic?.effectId == 'ahrya_extra_ally' ? 1 : 0);

  bool get hasTavernkeeperEquipped =>
      activeAllies.any((npc) => npc.id == 'giant_skull_tavernkeeper');

  bool get hasBaghestEye =>
      activeRelic?.effectId == 'baghest_eye' || baghestEyeOwned;

  bool isRelicUnlocked(String id) =>
      unlockedRelicIds.contains(id) ||
      relicLegacyAliases(id).any(unlockedRelicIds.contains);

  List<String> relicLegacyAliases(String id) {
    switch (id) {
      case 'vermi_decadenti_vervain':
        return const ['vermi_decadenti_vervein'];
      default:
        return const [];
    }
  }

  List<_RelicDef> availableStartingRelics() {
    return _allRelics
        .where((r) => r.unlockedByDefault || isRelicUnlocked(r.id))
        .where((r) => !(r.requiresNoTavernkeeper && hasTavernkeeperEquipped))
        .toList();
  }

  List<_RelicDef> randomStartingRelicChoices() {
    final relics = List<_RelicDef>.from(availableStartingRelics())
      ..shuffle(_random);
    return relics.take(3).toList();
  }

  String get activeElementId {
    if (activeArt != null) return activeArt!.elementId;
    return starterWeapon?.elementId ?? 'neutral';
  }

  int get maxFloors => tutorialRunActive ? 2 : 12;

  int get roomsPerFloor {
    if (tutorialRunActive) return 6;
    final survivability =
        widget.playerMaxHp ~/ 90 +
        widget.playerDefense ~/ 5 +
        widget.playerGrade;
    return (5 + survivability).clamp(5, 9).toInt();
  }

  int get totalPlannedRooms => maxFloors * roomsPerFloor + 7;

  int get effectiveRoom => max(0, room - 7);

  int get currentFloor {
    if (!floorZeroCompleted || room <= 7) return 0;
    if (effectiveRoom <= 0) return 1;
    return ((effectiveRoom - 1) ~/ roomsPerFloor + 1)
        .clamp(1, maxFloors)
        .toInt();
  }

  int get roomsRemainingInRun => max(0, maxRooms - room);

  bool get isInLastSixteenRooms => runActive && roomsRemainingInRun <= 16;

  int get sheetOffenseScore =>
      widget.playerDamage * 4 +
      widget.playerVc * 2 +
      widget.playerLevel +
      dungeonVolonta * 3 +
      attachedDropDamage * 3 +
      runDamageBonus * 2;

  int get sheetDefenseScore =>
      widget.playerMaxHp ~/ 6 +
      widget.playerDefense * 5 +
      widget.playerCm * 2 +
      dungeonMateria * 3 +
      playerShield ~/ 12 +
      attachedDropDefense * 3 +
      runDefenseBonus * 2;

  int get sheetMagicScore =>
      totalOculum * 5 +
      oculumCharges * 4 +
      dungeonOculum * 3 +
      unlockedActiveArtSkillIds().length * 10 +
      dungeonLevel * 6;

  int get sheetPowerScore =>
      sheetOffenseScore +
      sheetDefenseScore +
      sheetMagicScore +
      widget.playerGrade * 28 +
      currentFloor * 10 +
      killStreak * 3;

  String get sheetBuildNameIt {
    if (sheetMagicScore >= sheetOffenseScore &&
        sheetMagicScore >= sheetDefenseScore) {
      return 'Scheda Oculiana';
    }
    if (sheetDefenseScore >= sheetOffenseScore) {
      return 'Scheda Corazzata';
    }
    return 'Scheda Predatrice';
  }

  String get sheetBuildNameEn {
    if (sheetMagicScore >= sheetOffenseScore &&
        sheetMagicScore >= sheetDefenseScore) {
      return 'Oculian Sheet';
    }
    if (sheetDefenseScore >= sheetOffenseScore) {
      return 'Armored Sheet';
    }
    return 'Predator Sheet';
  }

  double get proceduralDifficultyMultiplier {
    // Versione leggermente più facile:
    // il dungeon legge ancora la scheda, ma non esplode troppo presto.
    final floorPressure = 1.0 + (currentFloor - 1) * 0.060;
    final roomPressure = 1.0 + (room / max(1, maxRooms)) * 0.38;
    final sheetPressure = 1.0 + (sheetPowerScore / 560.0).clamp(0.0, 0.88);
    final successPressure =
        1.0 + min(0.30, killStreak * 0.025 + dungeonLevel * 0.030);
    final postThirdRunPressure = runCount > 3 ? 1.07 : 1.0;

    return floorPressure *
        roomPressure *
        sheetPressure *
        successPressure *
        postThirdRunPressure *
        selectedDifficultyMultiplier;
  }

  List<String> preferredEnemyElementsForSheet() {
    if (sheetMagicScore >= sheetOffenseScore &&
        sheetMagicScore >= sheetDefenseScore) {
      return ['null', 'psico', 'sound', 'shadow', 'crystal', 'sun'];
    }

    if (sheetDefenseScore >= sheetOffenseScore) {
      return ['poison', 'blood', 'lava', 'sound', 'null', 'gravity'];
    }

    return ['earth', 'crystal', 'ice', 'gravity', 'bone', 'vapium'];
  }

  bool get isBossRoom =>
      floorZeroCompleted &&
      effectiveRoom > 0 &&
      effectiveRoom % roomsPerFloor == 0;
  bool get isBeforeBossRoom =>
      floorZeroCompleted &&
      effectiveRoom > 0 &&
      effectiveRoom % roomsPerFloor == roomsPerFloor - 1;

  int get totalElementalResist {
    final weaponElement = starterWeapon?.elementId ?? 'neutral';
    final active = activeElementId;
    return (elementalResist[active] ?? 0) +
        (elementalResist[weaponElement] ?? 0);
  }

  int get attachedDropDamage =>
      attachedDrops.fold(0, (sum, drop) => sum + drop.damageBonus);

  int get attachedDropDefense =>
      attachedDrops.fold(0, (sum, drop) => sum + drop.defenseBonus);

  int get totalDefense =>
      widget.playerDefense +
      titleDefenseBonus +
      runDefenseBonus +
      willMateriaDefense +
      artDefenseBonus() +
      activeArtSkillDefenseBonus() +
      attachedDefenseBonus +
      attachedDropDefense +
      setDefenseBonus +
      egoDefenseStacks * 2 +
      (starterWeapon?.defenseBonus ?? 0);

  int get totalDamage =>
      widget.playerDamage +
      titleDamageBonus +
      runDamageBonus +
      dungeonVolonta +
      artDamageBonus() +
      activeArtSkillDamageBonus() +
      attachedDamageBonus +
      attachedDropDamage +
      setDamageBonus +
      activeRelicRollBonus +
      egoWeaponStacks * 5 +
      (starterWeapon?.damageBonus ?? 0);

  int get expToNextDungeonLevel =>
      150 + dungeonLevel * 90 + runGrade * 30 + currentFloor * 22;

  int elementalDamageBonus() {
    switch (activeElementId) {
      case 'fire':
        return 3 + oculumArtPower + enemyBurn ~/ 2;
      case 'water':
        return 2 + oculumArtPower ~/ 2;
      case 'wind':
        return 2 + combo;
      case 'earth':
        return 1 + willMateriaDefense ~/ 3;
      case 'lightning':
        return 4 + runCritBonus ~/ 8;
      case 'ice':
        return 2 + enemyWeak;
      case 'sound':
        return 2 + runCritBonus ~/ 5;
      case 'poison':
        return 2 + enemyBleed ~/ 2;
      case 'ash':
        return 2 + playerShield ~/ 45;
      case 'blood':
        return 2 + runLifesteal + killStreak ~/ 2;
      case 'crystal':
        return 1 + totalDefense ~/ 5;
      case 'shadow':
        return 2 + runLifesteal;
      case 'moon':
        return 2 + oculumArtPower;
      case 'sun':
        return 2 + runCritBonus ~/ 4;
      case 'vapium':
        return 1 + playerShield ~/ 35;
      default:
        return 0;
    }
  }

  int artDamageBonus() {
    if (activeArt == null) return 0;
    if (activeArt!.effectId == 'blade_art') return 3 + oculumArtPower ~/ 2;
    return elementalDamageBonus();
  }

  int artDefenseBonus() {
    switch (activeElementId) {
      case 'earth':
        return 4 + willMateriaDefense ~/ 3;
      case 'water':
        return 2 + oculumArtPower ~/ 2;
      case 'wind':
        return dodgeCharges > 0 ? 2 : 1;
      case 'ice':
        return 2 + enemyWeak;
      case 'crystal':
        return 2 + totalDefense ~/ 8;
      case 'vapium':
        return 2 + playerShield ~/ 30;
      default:
        if (activeArt?.effectId == 'eyelid_art') {
          return 3 + willMateriaDefense ~/ 2;
        }
        return 0;
    }
  }

  int artOculumBonus() {
    switch (activeElementId) {
      case 'moon':
      case 'sun':
      case 'shadow':
      case 'crystal':
      case 'vapium':
        return 2;
      default:
        return activeArt == null ? 0 : 1;
    }
  }

  int calcThreat() {
    // La difficoltà legge davvero la scheda aperta:
    // HP, VC, CM, difesa, danno, livello, grado e poi i bonus ottenuti nella run.
    final baseSheetScore =
        widget.playerMaxHp ~/ 10 +
        widget.playerVc * 2 +
        widget.playerCm * 2 +
        widget.playerDefense * 4 +
        widget.playerDamage * 4 +
        widget.playerLevel * 2 +
        widget.playerGrade * 22;

    final runGrowthScore =
        dungeonLevel * 16 +
        dungeonResilienza * 4 +
        dungeonVolonta * 5 +
        dungeonMateria * 5 +
        dungeonOculum * 6 +
        attachedDropDamage * 6 +
        attachedDropDefense * 5 +
        attachedDrops.length * 8;

    final score = baseSheetScore + runGrowthScore;

    return ((score ~/ 70).clamp(1, 45)).toInt();
  }

  int clampPercent(num value) => value.clamp(0, 100).round().toInt();

  bool chance(num percent) => _random.nextInt(100) < clampPercent(percent);

  ({String id, String nameIt, String nameEn, int dayInPhase}) cyclePhase() {
    final day = cycleDay.clamp(1, 369).toInt();
    if (day <= 36) {
      return (
        id: 'safe_monster',
        nameIt: 'Safe Monster',
        nameEn: 'Safe Monster',
        dayInPhase: day,
      );
    }
    if (day <= 72) {
      return (
        id: 'illness',
        nameIt: 'Illness',
        nameEn: 'Illness',
        dayInPhase: day - 36,
      );
    }
    if (day <= 108) {
      return (
        id: 'little_breath',
        nameIt: 'Little Breath',
        nameEn: 'Little Breath',
        dayInPhase: day - 72,
      );
    }
    if (day <= 144) {
      return (
        id: 'fertile_rain',
        nameIt: 'Piogge Fertilizzanti',
        nameEn: 'Fertilizing Rains',
        dayInPhase: day - 108,
      );
    }
    if (day <= 150) {
      return (
        id: 'sun',
        nameIt: 'The Sun',
        nameEn: 'The Sun',
        dayInPhase: day - 144,
      );
    }
    if (day <= 183) {
      return (
        id: 'half_cycle',
        nameIt: 'Mezzo Ciclo',
        nameEn: 'Half Cycle',
        dayInPhase: day - 150,
      );
    }
    if (day <= 189) {
      return (
        id: 'moon',
        nameIt: 'The Moon',
        nameEn: 'The Moon',
        dayInPhase: day - 183,
      );
    }
    if (day <= 225) {
      return (
        id: 'fate',
        nameIt: 'The Fate',
        nameEn: 'The Fate',
        dayInPhase: day - 189,
      );
    }
    if (day <= 261) {
      return (
        id: 'heat',
        nameIt: 'Caldo Infernale',
        nameEn: 'Infernal Heat',
        dayInPhase: day - 225,
      );
    }
    if (day <= 297) {
      return (
        id: 'null',
        nameIt: 'The Null',
        nameEn: 'The Null',
        dayInPhase: day - 261,
      );
    }
    if (day <= 333) {
      return (
        id: 'ice',
        nameIt: 'Ghiaccio Imponente',
        nameEn: 'Imposing Ice',
        dayInPhase: day - 297,
      );
    }
    return (
      id: 'last_cycle',
      nameIt: 'Ultimo Ciclo',
      nameEn: 'Last Cycle',
      dayInPhase: day - 333,
    );
  }

  String cyclePhaseLine() {
    final phase = cyclePhase();
    return t(
      'Ciclo giorno $cycleDay/369 - ${phase.nameIt} ${phase.dayInPhase}',
      'Cycle day $cycleDay/369 - ${phase.nameEn} ${phase.dayInPhase}',
    );
  }

  int calendarEventBonus(String eventId) {
    final phase = cyclePhase().id;
    if (phase == 'little_breath' && eventId == 'title') return 2;
    if (phase == 'fate' && eventId == 'title') return 4;
    if (phase == 'moon' && eventId == 'rest') return 4;
    if (phase == 'half_cycle' && eventId == 'rest') return 2;
    if (phase == 'sun' && eventId == 'fire') return 3;
    if (phase == 'ice' && eventId == 'ice') return 3;
    return 0;
  }

  int calendarDangerBonus(String eventId) {
    final phase = cyclePhase().id;
    if (phase == 'illness' && eventId == 'trap') return 2;
    if (phase == 'heat' && eventId == 'rest') return 2;
    if (phase == 'ice' && eventId == 'rest') return 2;
    if (phase == 'null' && eventId == 'combat') return 3;
    if (phase == 'fertile_rain' && eventId == 'trap') return 1;
    return 0;
  }

  void addLog(String message) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    log.insert(0, '[$hh:$mm] $message');
    if (log.length > 160) log.removeRange(160, log.length);
  }

  Map<String, dynamic> enemyToCheckpoint(_EnemyInstance enemy) {
    return {
      'nameIt': enemy.nameIt,
      'nameEn': enemy.nameEn,
      'elementId': enemy.elementId,
      'hp': enemy.hp,
      'maxHp': enemy.maxHp,
      'attack': enemy.attack,
      'defense': enemy.defense,
      'boss': enemy.boss,
      'elite': enemy.elite,
      'fetal': enemy.fetal,
      'level': enemy.level,
      'grade': enemy.grade,
      'originalPower': enemy.originalPower,
      'adaptedAttackTypes': enemy.adaptedAttackTypes.toList(),
      'monsterId': enemy.monsterId,
      'skillIds': enemy.skillIds,
      'dropIds': enemy.dropIds,
      'spriteAssetPath': enemy.spriteAssetPath,
      'stunTurns': enemy.stunTurns,
      'slowTurns': enemy.slowTurns,
      'burnTurns': enemy.burnTurns,
      'bleedTurns': enemy.bleedTurns,
      'attackDebuffTurns': enemy.attackDebuffTurns,
      'defenseDebuffTurns': enemy.defenseDebuffTurns,
      'attackDebuffValue': enemy.attackDebuffValue,
      'defenseDebuffValue': enemy.defenseDebuffValue,
      'burnPotency': enemy.burnPotency,
      'bleedPotency': enemy.bleedPotency,
    };
  }

  _EnemyInstance enemyFromCheckpoint(Map<String, dynamic> data) {
    return _EnemyInstance(
      nameIt: data['nameIt'] as String? ?? 'Nemico Registrato',
      nameEn: data['nameEn'] as String? ?? 'Recorded Enemy',
      elementId: data['elementId'] as String? ?? 'neutral',
      hp: (data['hp'] as num?)?.toInt() ?? 1,
      maxHp: (data['maxHp'] as num?)?.toInt() ?? 1,
      attack: (data['attack'] as num?)?.toInt() ?? 1,
      defense: (data['defense'] as num?)?.toInt() ?? 0,
      boss: readSavedBool(data['boss']),
      elite: readSavedBool(data['elite']),
      fetal: readSavedBool(data['fetal']),
      level: (data['level'] as num?)?.toInt() ?? 1,
      grade: (data['grade'] as num?)?.toInt() ?? 0,
      originalPower: (data['originalPower'] as num?)?.toInt() ?? 0,
      adaptedAttackTypes: ((data['adaptedAttackTypes'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet(),
      monsterId: data['monsterId'] as String?,
      skillIds: ((data['skillIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      dropIds: ((data['dropIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      spriteAssetPath: data['spriteAssetPath'] as String?,
      stunTurns: (data['stunTurns'] as num?)?.toInt() ?? 0,
      slowTurns: (data['slowTurns'] as num?)?.toInt() ?? 0,
      burnTurns: (data['burnTurns'] as num?)?.toInt() ?? 0,
      bleedTurns: (data['bleedTurns'] as num?)?.toInt() ?? 0,
      attackDebuffTurns: (data['attackDebuffTurns'] as num?)?.toInt() ?? 0,
      defenseDebuffTurns: (data['defenseDebuffTurns'] as num?)?.toInt() ?? 0,
      attackDebuffValue: (data['attackDebuffValue'] as num?)?.toInt() ?? 0,
      defenseDebuffValue: (data['defenseDebuffValue'] as num?)?.toInt() ?? 0,
      burnPotency: (data['burnPotency'] as num?)?.toInt() ?? 0,
      bleedPotency: (data['bleedPotency'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> buildRunCheckpointData() {
    return {
      'runActive': runActive,
      'inCombat': inCombat,
      'gameOver': gameOver,
      'victory': victory,
      'room': room,
      'maxRooms': maxRooms,
      'threat': threat,
      'runGrade': runGrade,
      'cycleDay': cycleDay,
      'dungeonFloor': dungeonFloor,
      'currentFloorStart': currentFloorStart,
      'floorZeroCompleted': floorZeroCompleted,
      'dungeonLevel': dungeonLevel,
      'dungeonExp': dungeonExp,
      'dungeonResilienza': dungeonResilienza,
      'dungeonVolonta': dungeonVolonta,
      'dungeonMateria': dungeonMateria,
      'dungeonOculum': dungeonOculum,
      'spentRunResilienza': spentRunResilienza,
      'spentRunVolonta': spentRunVolonta,
      'spentRunMateria': spentRunMateria,
      'spentRunOculum': spentRunOculum,
      'playerMaxHp': playerMaxHp,
      'playerHp': playerHp,
      'playerShield': playerShield,
      'playerOculumShield': playerOculumShield,
      'playerOculumShieldMax': playerOculumShieldMax,
      'dungeonKarma': dungeonKarma,
      'oculumMaxCharges': oculumMaxCharges,
      'oculumCharges': oculumCharges,
      'obserInRun': obserInRun,
      'ascensionDustInRun': ascensionDustInRun,
      'soulShards': soulShards,
      'keys': keys,
      'posteaRunicMetalKg': posteaRunicMetalKg,
      'runDamageBonus': runDamageBonus,
      'runDefenseBonus': runDefenseBonus,
      'runCritBonus': runCritBonus,
      'runLifesteal': runLifesteal,
      'runHealOnExplore': runHealOnExplore,
      'thornWhipRollBonus': thornWhipRollBonus,
      'dodgeCharges': dodgeCharges,
      'criticalShieldActive': criticalShieldActive,
      'criticalShieldBlocks': criticalShieldBlocks,
      'reactionAvailable': reactionAvailable,
      'rebirthBlessingActive': rebirthBlessingActive,
      'freeReforges': freeReforges,
      'reforgeCount': reforgeCount,
      'blacksmithFavor': blacksmithFavor,
      'attachedDamageBonus': attachedDamageBonus,
      'attachedDefenseBonus': attachedDefenseBonus,
      'potionMinor': potionMinor,
      'potionMajor': potionMajor,
      'potionShield': potionShield,
      'potionOculum': potionOculum,
      'potionCleanse': potionCleanse,
      'potionSmoke': potionSmoke,
      'artTechniqueCooldown': artTechniqueCooldown,
      'artTechniqueUses': artTechniqueUses,
      'relicSkillUsesThisFloor': relicSkillUsesThisFloor,
      'relicSkillUsesThisRoom': relicSkillUsesThisRoom,
      'fifiSleepActions': fifiSleepActions,
      'vervainBuffFloor': vervainBuffFloor,
      'skeletonHandsHp': skeletonHandsHp,
      'skeletonHandsMaxHp': skeletonHandsMaxHp,
      'cipoSerpentHp': cipoSerpentHp,
      'cipoSerpentMaxHp': cipoSerpentMaxHp,
      'floralGuardCharges': floralGuardCharges,
      'egoShieldHp': egoShieldHp,
      'egoWeaponStacks': egoWeaponStacks,
      'egoDefenseStacks': egoDefenseStacks,
      'relicNextRollBonus': relicNextRollBonus,
      'tribalDanceBuffFloor': tribalDanceBuffFloor,
      'egoShieldBuffFloor': egoShieldBuffFloor,
      'pawnHp': pawnHp,
      'pawnMaxHp': pawnMaxHp,
      'pawnShield': pawnShield,
      'posteaEliteGuardHp': posteaEliteGuardHp,
      'posteaEliteGuardMaxHp': posteaEliteGuardMaxHp,
      'posteaEliteGuardShield': posteaEliteGuardShield,
      'posteaEliteGuardCriticalShieldActive':
          posteaEliteGuardCriticalShieldActive,
      'skellyGuardCharges': skellyGuardCharges,
      'combo': combo,
      'killStreak': killStreak,
      'roomsWithoutDamage': roomsWithoutDamage,
      'fightsSinceTavernRest': fightsSinceTavernRest,
      'consecutivePlayerCritsThisFight': consecutivePlayerCritsThisFight,
      'defeatedEnemyPowerTotal': defeatedEnemyPowerTotal,
      'defeatedEnemyExpTotal': defeatedEnemyExpTotal,
      'defeatedBossCount': defeatedBossCount,
      'defeatedEliteCount': defeatedEliteCount,
      'valleyEncounterSeenThisRun': valleyEncounterSeenThisRun,
      'valleyTrainingUsedThisRun': valleyTrainingUsedThisRun,
      'valleyTrainingActive': valleyTrainingActive,
      'valleyTrainingRewardClaimed': valleyTrainingRewardClaimed,
      'valleyParticipatedInFight': valleyParticipatedInFight,
      'valleyBloomResolvedThisFight': valleyBloomResolvedThisFight,
      'valleySacrificedInPostea': valleySacrificedInPostea,
      'valleyTurnsLeft': valleyTurnsLeft,
      'valleyHp': valleyHp,
      'valleyMaxHp': valleyMaxHp,
      'valleyAttack': valleyAttack,
      'valleyDefense': valleyDefense,
      'valleyBloomGuards': valleyBloomGuards,
      'valleyTrainingTurnsLeft': valleyTrainingTurnsLeft,
      'merchantActionUsedThisRoom': merchantActionUsedThisRoom,
      'blacksmithActionUsedThisRoom': blacksmithActionUsedThisRoom,
      'dropActionUsedThisRoom': dropActionUsedThisRoom,
      'restActionUsedThisRoom': restActionUsedThisRoom,
      'tavernMealUsedThisRoom': tavernMealUsedThisRoom,
      'tavernMerchantActionUsedThisRoom': tavernMerchantActionUsedThisRoom,
      'tavernBlacksmithActionUsedThisRoom': tavernBlacksmithActionUsedThisRoom,
      'tavernSleepUsedThisRoom': tavernSleepUsedThisRoom,
      'monsterVillageFightActive': monsterVillageFightActive,
      'sparklingGears': sparklingGears,

      'enemyHp': enemyHp,
      'enemyMaxHp': enemyMaxHp,
      'enemyAttack': enemyAttack,
      'enemyDefense': enemyDefense,
      'enemyBleed': enemyBleed,
      'enemyBurn': enemyBurn,
      'enemyWeak': enemyWeak,
      'playerStunTurns': playerStunTurns,
      'playerSlowTurns': playerSlowTurns,
      'playerBurnTurns': playerBurnTurns,
      'playerBleedTurns': playerBleedTurns,
      'playerAttackDebuffTurns': playerAttackDebuffTurns,
      'playerDefenseDebuffTurns': playerDefenseDebuffTurns,
      'playerAttackDebuffValue': playerAttackDebuffValue,
      'playerDefenseDebuffValue': playerDefenseDebuffValue,
      'enemyIsBoss': enemyIsBoss,
      'enemyIsElite': enemyIsElite,
      'enemyNameIt': enemyNameIt,
      'enemyNameEn': enemyNameEn,
      'enemyElementId': enemyElementId,
      'enemyParty': enemyParty.map(enemyToCheckpoint).toList(),
      'defeatedEnemyNamesIt': defeatedEnemyNamesIt,
      'defeatedEnemyNamesEn': defeatedEnemyNamesEn,

      'activeQuestId': activeQuestId,
      'activeQuestIt': activeQuestIt,
      'activeQuestEn': activeQuestEn,
      'activeQuestProgress': activeQuestProgress,
      'activeQuestGoal': activeQuestGoal,
      'questCompleted': questCompleted,
      'activeSkillQuestId': activeSkillQuestId,
      'activeSkillQuestIt': activeSkillQuestIt,
      'activeSkillQuestEn': activeSkillQuestEn,
      'activeSkillQuestProgress': activeSkillQuestProgress,
      'activeSkillQuestGoal': activeSkillQuestGoal,
      'starterWeaponId': starterWeapon?.id,
      'activeCostumeId': activeCostume?.id,
      'activeArtId': activeArt?.effectId,
      'selectedRunArtIds': selectedRunArtIds.toList(),
      'oculianAllianceActive': hasOculianPact,
      'gufusUsedThisRun': gufusUsedThisRun,
      'posteaGufusEventActive': posteaGufusEventActive,
      'posteaGufusEventPhase': posteaGufusEventPhase,
      'posteaScientistTurnCounter': posteaScientistTurnCounter,
      'posteaScientistEnhanced': posteaScientistEnhanced,
      'activeRelicId': activeRelic?.id,
      'activeCharacterOriginId': activeCharacterOrigin?.id,
      'equippedTitleIds': equippedTitleIds.toList(),
      'activeAllyIds': activeAllies.map((npc) => npc.id).toList(),
      'purchasedRelics': purchasedRelics,
      'runBoons': runBoons,
      'smallNpcActions': smallNpcActions,
      'weakNpcRunEncounteredIds': weakNpcRunEncounteredIds.toList(),
      'earlyDustRoomsClaimed': earlyDustRoomsClaimed.toList(),
      'floorSaveEventsClaimed': floorSaveEventsClaimed.toList(),
      'randomTitleFloorRewardsClaimed': randomTitleFloorRewardsClaimed.toList(),
      'titleChoiceRoomsClaimed': titleChoiceRoomsClaimed.toList(),
      'gradeEventsSeenThisRun': gradeEventsSeenThisRun.toList(),
      'artSkillChoices': artSkillChoices,
      'artSkillProgress': artSkillProgress.map(
        (key, value) => MapEntry(key, value.level),
      ),
      'relicOpenLastFloor': relicOpenLastFloor,
      'elementalResist': elementalResist,
      'attachedDropIds': attachedDrops.map((drop) => drop.dropId).toList(),
      'inventoryDropIds': inventoryDrops.map((drop) => drop.id).toList(),
      'log': log.take(80).toList(),
      'textIt': textIt,
      'textEn': textEn,
      'choicePanelMode': choicePanelMode,
      'showEventChoices': showEventChoices,
      'showCombatActions': showCombatActions,
      'showLogPanel': showLogPanel,
      'showArtBoard': showArtBoard,
      'showWeaponBoard': showWeaponBoard,
      'showSpritePanel': showSpritePanel,
      'showSpriteCodex': showSpriteCodex,
      'classicCombatView': classicCombatView,
      'quickEyeCollapsed': quickEyeCollapsed,
      'playerSpriteShape': playerSpriteShape,
      'playerSpriteAccent': playerSpriteAccent,
      'quickTileOrder': quickTileOrder,
    };
  }

  Future<void> saveRunCheckpoint({
    String reasonIt = 'Checkpoint salvato.',
    String reasonEn = 'Checkpoint saved.',
  }) async {
    if (!runActive || gameOver || playerHp <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'oculumDungeon.activeRunCheckpoint',
      jsonEncode(buildRunCheckpointData()),
    );

    addLog(t(reasonIt, reasonEn));
  }

  Future<void> clearRunCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('oculumDungeon.activeRunCheckpoint');
  }

  Future<void> declineActiveRunCheckpoint({
    String? messageIt,
    String? messageEn,
    bool stopRun = false,
  }) async {
    await clearRunCheckpoint();
    if (!mounted) return;

    setState(() {
      clearChoices();

      if (stopRun) {
        runActive = false;
        inCombat = false;
        gameOver = false;
        enemyParty.clear();
        syncPrimaryEnemyFromParty();
      }

      textIt =
          messageIt ??
          'Hai scelto di non usare questo salvataggio.\n\n'
              'Il ricordo viene strappato dall’occhio, ma gli sblocchi permanenti restano.';
      textEn =
          messageEn ??
          'You chose not to use this save.\n\n'
              'The memory is torn from the eye, but permanent unlocks remain.';

      addLog(t('Checkpoint attivo rifiutato.', 'Active checkpoint declined.'));
    });
  }

  void restoreRunCheckpoint(Map<String, dynamic> data) {
    runActive = readSavedBool(data['runActive']);
    inCombat = readSavedBool(data['inCombat']);
    gameOver = false;
    victory = false;

    room = (data['room'] as num?)?.toInt() ?? room;
    maxRooms = (data['maxRooms'] as num?)?.toInt() ?? maxRooms;
    threat = (data['threat'] as num?)?.toInt() ?? threat;
    runGrade = (data['runGrade'] as num?)?.toInt() ?? runGrade;
    cycleDay = (data['cycleDay'] as num?)?.toInt() ?? cycleDay;
    dungeonFloor = (data['dungeonFloor'] as num?)?.toInt() ?? dungeonFloor;
    currentFloorStart =
        (data['currentFloorStart'] as num?)?.toInt() ?? currentFloorStart;
    floorZeroCompleted = readSavedBool(data['floorZeroCompleted']);

    dungeonLevel = (data['dungeonLevel'] as num?)?.toInt() ?? dungeonLevel;
    dungeonExp = (data['dungeonExp'] as num?)?.toInt() ?? dungeonExp;
    dungeonResilienza =
        (data['dungeonResilienza'] as num?)?.toInt() ?? dungeonResilienza;
    dungeonVolonta =
        (data['dungeonVolonta'] as num?)?.toInt() ?? dungeonVolonta;
    dungeonMateria =
        (data['dungeonMateria'] as num?)?.toInt() ?? dungeonMateria;
    dungeonOculum = (data['dungeonOculum'] as num?)?.toInt() ?? dungeonOculum;
    spentRunResilienza =
        (data['spentRunResilienza'] as num?)?.toInt() ?? spentRunResilienza;
    spentRunVolonta =
        (data['spentRunVolonta'] as num?)?.toInt() ?? spentRunVolonta;
    spentRunMateria =
        (data['spentRunMateria'] as num?)?.toInt() ?? spentRunMateria;
    spentRunOculum =
        (data['spentRunOculum'] as num?)?.toInt() ?? spentRunOculum;

    playerMaxHp = (data['playerMaxHp'] as num?)?.toInt() ?? playerMaxHp;
    playerHp = (data['playerHp'] as num?)?.toInt() ?? playerHp;
    playerShield = (data['playerShield'] as num?)?.toInt() ?? playerShield;
    playerOculumShield =
        (data['playerOculumShield'] as num?)?.toInt() ?? playerOculumShield;
    playerOculumShieldMax =
        (data['playerOculumShieldMax'] as num?)?.toInt() ??
        playerOculumShieldMax;
    dungeonKarma = (data['dungeonKarma'] as num?)?.toInt() ?? dungeonKarma;
    playerOculumShieldMax = max(playerOculumShieldMax, playerOculumShield);
    oculumMaxCharges =
        (data['oculumMaxCharges'] as num?)?.toInt() ?? oculumMaxCharges;
    oculumCharges = (data['oculumCharges'] as num?)?.toInt() ?? oculumCharges;
    oculumMaxCharges = max(0, oculumMaxCharges).toInt();
    oculumCharges = oculumCharges.clamp(0, oculumMaxCharges).toInt();

    obserInRun = (data['obserInRun'] as num?)?.toInt() ?? obserInRun;
    ascensionDustInRun =
        (data['ascensionDustInRun'] as num?)?.toInt() ?? ascensionDustInRun;
    soulShards = (data['soulShards'] as num?)?.toInt() ?? soulShards;
    keys = (data['keys'] as num?)?.toInt() ?? keys;
    posteaRunicMetalKg =
        (data['posteaRunicMetalKg'] as num?)?.toInt() ??
        (data['posteaRunicMetalSixths'] as num?)?.toInt() ??
        (data['posteaRunicMetalHalfKg'] as num?)?.toInt() ??
        posteaRunicMetalKg;

    runDamageBonus =
        (data['runDamageBonus'] as num?)?.toInt() ?? runDamageBonus;
    runDefenseBonus =
        (data['runDefenseBonus'] as num?)?.toInt() ?? runDefenseBonus;
    runCritBonus = (data['runCritBonus'] as num?)?.toInt() ?? runCritBonus;
    runLifesteal = (data['runLifesteal'] as num?)?.toInt() ?? runLifesteal;
    runHealOnExplore =
        (data['runHealOnExplore'] as num?)?.toInt() ?? runHealOnExplore;
    thornWhipRollBonus =
        (data['thornWhipRollBonus'] as num?)?.toInt() ?? thornWhipRollBonus;
    dodgeCharges = (data['dodgeCharges'] as num?)?.toInt() ?? dodgeCharges;
    criticalShieldActive = readSavedBool(data['criticalShieldActive']);
    criticalShieldBlocks =
        (data['criticalShieldBlocks'] as num?)?.toInt() ?? criticalShieldBlocks;
    reactionAvailable = readSavedBool(
      data['reactionAvailable'],
      fallback: true,
    );
    rebirthBlessingActive = readSavedBool(data['rebirthBlessingActive']);

    freeReforges = (data['freeReforges'] as num?)?.toInt() ?? freeReforges;
    reforgeCount = (data['reforgeCount'] as num?)?.toInt() ?? reforgeCount;
    blacksmithFavor =
        (data['blacksmithFavor'] as num?)?.toInt() ?? blacksmithFavor;
    attachedDamageBonus =
        (data['attachedDamageBonus'] as num?)?.toInt() ?? attachedDamageBonus;
    attachedDefenseBonus =
        (data['attachedDefenseBonus'] as num?)?.toInt() ?? attachedDefenseBonus;

    potionMinor = (data['potionMinor'] as num?)?.toInt() ?? potionMinor;
    potionMajor = (data['potionMajor'] as num?)?.toInt() ?? potionMajor;
    potionShield = (data['potionShield'] as num?)?.toInt() ?? potionShield;
    potionOculum = (data['potionOculum'] as num?)?.toInt() ?? potionOculum;
    potionCleanse = (data['potionCleanse'] as num?)?.toInt() ?? potionCleanse;
    potionSmoke = (data['potionSmoke'] as num?)?.toInt() ?? potionSmoke;
    artTechniqueCooldown =
        (data['artTechniqueCooldown'] as num?)?.toInt() ?? artTechniqueCooldown;
    artTechniqueUses =
        (data['artTechniqueUses'] as num?)?.toInt() ?? artTechniqueUses;
    relicSkillUsesThisFloor =
        (data['relicSkillUsesThisFloor'] as num?)?.toInt() ??
        relicSkillUsesThisFloor;
    relicSkillUsesThisRoom =
        (data['relicSkillUsesThisRoom'] as num?)?.toInt() ??
        relicSkillUsesThisRoom;
    fifiSleepActions =
        (data['fifiSleepActions'] as num?)?.toInt() ?? fifiSleepActions;
    vervainBuffFloor =
        (data['vervainBuffFloor'] as num?)?.toInt() ??
        (data['verveinBuffFloor'] as num?)?.toInt() ??
        vervainBuffFloor;
    skeletonHandsHp =
        (data['skeletonHandsHp'] as num?)?.toInt() ?? skeletonHandsHp;
    skeletonHandsMaxHp =
        (data['skeletonHandsMaxHp'] as num?)?.toInt() ?? skeletonHandsMaxHp;
    cipoSerpentHp = (data['cipoSerpentHp'] as num?)?.toInt() ?? cipoSerpentHp;
    cipoSerpentMaxHp =
        (data['cipoSerpentMaxHp'] as num?)?.toInt() ?? cipoSerpentMaxHp;
    floralGuardCharges =
        (data['floralGuardCharges'] as num?)?.toInt() ?? floralGuardCharges;
    egoShieldHp = (data['egoShieldHp'] as num?)?.toInt() ?? egoShieldHp;
    egoWeaponStacks =
        (data['egoWeaponStacks'] as num?)?.toInt() ?? egoWeaponStacks;
    egoDefenseStacks =
        (data['egoDefenseStacks'] as num?)?.toInt() ?? egoDefenseStacks;
    relicNextRollBonus =
        (data['relicNextRollBonus'] as num?)?.toInt() ?? relicNextRollBonus;
    tribalDanceBuffFloor =
        (data['tribalDanceBuffFloor'] as num?)?.toInt() ?? tribalDanceBuffFloor;
    egoShieldBuffFloor =
        (data['egoShieldBuffFloor'] as num?)?.toInt() ?? egoShieldBuffFloor;
    pawnHp = (data['pawnHp'] as num?)?.toInt() ?? pawnHp;
    pawnMaxHp = (data['pawnMaxHp'] as num?)?.toInt() ?? pawnMaxHp;
    pawnShield = (data['pawnShield'] as num?)?.toInt() ?? pawnShield;
    posteaEliteGuardHp =
        (data['posteaEliteGuardHp'] as num?)?.toInt() ?? posteaEliteGuardHp;
    posteaEliteGuardMaxHp =
        (data['posteaEliteGuardMaxHp'] as num?)?.toInt() ??
        posteaEliteGuardMaxHp;
    posteaEliteGuardShield =
        (data['posteaEliteGuardShield'] as num?)?.toInt() ??
        posteaEliteGuardShield;
    posteaEliteGuardCriticalShieldActive = readSavedBool(
      data['posteaEliteGuardCriticalShieldActive'],
    );
    skellyGuardCharges =
        (data['skellyGuardCharges'] as num?)?.toInt() ?? skellyGuardCharges;
    combo = (data['combo'] as num?)?.toInt() ?? combo;
    killStreak = (data['killStreak'] as num?)?.toInt() ?? killStreak;
    roomsWithoutDamage =
        (data['roomsWithoutDamage'] as num?)?.toInt() ?? roomsWithoutDamage;
    fightsSinceTavernRest =
        (data['fightsSinceTavernRest'] as num?)?.toInt() ??
        fightsSinceTavernRest;
    consecutivePlayerCritsThisFight =
        (data['consecutivePlayerCritsThisFight'] as num?)?.toInt() ??
        consecutivePlayerCritsThisFight;
    defeatedEnemyPowerTotal =
        (data['defeatedEnemyPowerTotal'] as num?)?.toInt() ??
        defeatedEnemyPowerTotal;
    defeatedEnemyExpTotal =
        (data['defeatedEnemyExpTotal'] as num?)?.toInt() ??
        defeatedEnemyExpTotal;
    defeatedBossCount =
        (data['defeatedBossCount'] as num?)?.toInt() ?? defeatedBossCount;
    defeatedEliteCount =
        (data['defeatedEliteCount'] as num?)?.toInt() ?? defeatedEliteCount;
    valleyEncounterSeenThisRun = readSavedBool(
      data['valleyEncounterSeenThisRun'],
    );
    valleyTrainingUsedThisRun = readSavedBool(
      data['valleyTrainingUsedThisRun'],
    );
    valleyTrainingActive = readSavedBool(data['valleyTrainingActive']);
    valleyTrainingRewardClaimed = readSavedBool(
      data['valleyTrainingRewardClaimed'],
    );
    valleyParticipatedInFight = readSavedBool(
      data['valleyParticipatedInFight'],
    );
    valleyBloomResolvedThisFight = readSavedBool(
      data['valleyBloomResolvedThisFight'],
    );
    valleySacrificedInPostea =
        readSavedBool(data['valleySacrificedInPostea']) ||
        valleySacrificedInPostea;
    valleyTurnsLeft =
        (data['valleyTurnsLeft'] as num?)?.toInt() ?? valleyTurnsLeft;
    valleyHp = (data['valleyHp'] as num?)?.toInt() ?? valleyHp;
    valleyMaxHp = (data['valleyMaxHp'] as num?)?.toInt() ?? valleyMaxHp;
    valleyAttack = (data['valleyAttack'] as num?)?.toInt() ?? valleyAttack;
    valleyDefense = (data['valleyDefense'] as num?)?.toInt() ?? valleyDefense;
    valleyBloomGuards =
        (data['valleyBloomGuards'] as num?)?.toInt() ?? valleyBloomGuards;
    valleyTrainingTurnsLeft =
        (data['valleyTrainingTurnsLeft'] as num?)?.toInt() ??
        valleyTrainingTurnsLeft;
    merchantActionUsedThisRoom = readSavedBool(
      data['merchantActionUsedThisRoom'],
    );
    blacksmithActionUsedThisRoom = readSavedBool(
      data['blacksmithActionUsedThisRoom'],
    );
    dropActionUsedThisRoom = readSavedBool(data['dropActionUsedThisRoom']);
    restActionUsedThisRoom = readSavedBool(data['restActionUsedThisRoom']);
    tavernMealUsedThisRoom = readSavedBool(data['tavernMealUsedThisRoom']);
    tavernMerchantActionUsedThisRoom = readSavedBool(
      data['tavernMerchantActionUsedThisRoom'],
    );
    tavernBlacksmithActionUsedThisRoom = readSavedBool(
      data['tavernBlacksmithActionUsedThisRoom'],
    );
    tavernSleepUsedThisRoom = readSavedBool(data['tavernSleepUsedThisRoom']);
    monsterVillageFightActive = readSavedBool(
      data['monsterVillageFightActive'],
    );
    sparklingGears =
        (data['sparklingGears'] as num?)?.toInt() ?? sparklingGears;

    activeQuestId = data['activeQuestId'] as String? ?? activeQuestId;
    activeQuestIt = data['activeQuestIt'] as String? ?? activeQuestIt;
    activeQuestEn = data['activeQuestEn'] as String? ?? activeQuestEn;
    activeQuestProgress =
        (data['activeQuestProgress'] as num?)?.toInt() ?? activeQuestProgress;
    activeQuestGoal =
        (data['activeQuestGoal'] as num?)?.toInt() ?? activeQuestGoal;
    questCompleted = readSavedBool(data['questCompleted']);

    activeSkillQuestId =
        data['activeSkillQuestId'] as String? ?? activeSkillQuestId;
    activeSkillQuestIt =
        data['activeSkillQuestIt'] as String? ?? activeSkillQuestIt;
    activeSkillQuestEn =
        data['activeSkillQuestEn'] as String? ?? activeSkillQuestEn;
    activeSkillQuestProgress =
        (data['activeSkillQuestProgress'] as num?)?.toInt() ??
        activeSkillQuestProgress;
    activeSkillQuestGoal =
        (data['activeSkillQuestGoal'] as num?)?.toInt() ?? activeSkillQuestGoal;
    final weaponId = data['starterWeaponId'] as String?;
    starterWeapon = weaponId == null
        ? null
        : _starterWeapons
              .where((w) => w.id == weaponId)
              .cast<_StarterWeapon?>()
              .firstWhere((w) => w != null, orElse: () => null);

    final costumeId = data['activeCostumeId'] as String?;
    activeCostume = costumeId == null
        ? null
        : _runCostumes
              .where((c) => c.id == costumeId)
              .cast<_RunCostume?>()
              .firstWhere((c) => c != null, orElse: () => null);

    final artId = data['activeArtId'] as String?;
    activeArt = artId == null
        ? null
        : _allArts
              .where((a) => a.effectId == artId)
              .cast<_DungeonArt?>()
              .firstWhere((a) => a != null, orElse: () => null);
    selectedRunArtIds
      ..clear()
      ..addAll(
        ((data['selectedRunArtIds'] as List?) ?? const []).map(
          (e) => e.toString(),
        ),
      );
    if (selectedRunArtIds.isEmpty && activeArt != null) {
      selectedRunArtIds.add(activeArt!.effectId);
    }
    oculianAllianceActive = readSavedBool(data['oculianAllianceActive']);
    gufusUsedThisRun = readSavedBool(data['gufusUsedThisRun']);
    posteaGufusEventActive = readSavedBool(data['posteaGufusEventActive']);
    posteaGufusEventPhase =
        data['posteaGufusEventPhase'] as String? ?? posteaGufusEventPhase;
    posteaScientistTurnCounter =
        (data['posteaScientistTurnCounter'] as num?)?.toInt() ??
        posteaScientistTurnCounter;
    posteaScientistEnhanced =
        readSavedBool(data['posteaScientistEnhanced']) ||
        posteaScientistEnhanced;

    final relicId = data['activeRelicId'] as String?;
    activeRelic = relicId == null
        ? null
        : _allRelics
              .where((r) => r.id == relicId)
              .cast<_RelicDef?>()
              .firstWhere((r) => r != null, orElse: () => null);

    final originId = data['activeCharacterOriginId'] as String?;
    activeCharacterOrigin = originId == null
        ? null
        : _characterOrigins
              .where((origin) => origin.id == originId)
              .cast<_CharacterOrigin?>()
              .firstWhere((origin) => origin != null, orElse: () => null);
    if (activeCharacterOrigin?.id == 'male_oculian_cultist' ||
        activeCharacterOrigin?.id == 'female_oculian_cultist') {
      oculianAllianceActive = true;
    }

    equippedTitleIds
      ..clear()
      ..addAll(readSavedStringList(data['equippedTitleIds']));

    activeAllies
      ..clear()
      ..addAll(
        _goodNpcs.where(
          (npc) =>
              ((data['activeAllyIds'] as List?) ?? const []).contains(npc.id),
        ),
      );
    if (valleySacrificedInPostea) {
      activeAllies.removeWhere(
        (npc) => npc.id == 'valley_child_of_mother_nature',
      );
      selectedAllyIds.remove('valley_child_of_mother_nature');
      unlockedNpcIds.remove('valley_child_of_mother_nature');
    }

    purchasedRelics
      ..clear()
      ..addAll(readSavedStringList(data['purchasedRelics']));

    runBoons
      ..clear()
      ..addAll(readSavedStringList(data['runBoons']));

    smallNpcActions
      ..clear()
      ..addAll(readSavedIntMap(data['smallNpcActions']));

    weakNpcRunEncounteredIds
      ..clear()
      ..addAll(readSavedStringList(data['weakNpcRunEncounteredIds']));

    earlyDustRoomsClaimed
      ..clear()
      ..addAll(readSavedIntList(data['earlyDustRoomsClaimed']));

    for (final npc in activeAllies.where(isSmallNpc)) {
      prepareSmallNpcActions(npc);
    }
    if (posteaEliteGuardInParty) {
      activatePosteaEliteGuard();
    } else {
      clearPosteaEliteGuardState();
    }

    floorSaveEventsClaimed
      ..clear()
      ..addAll(readSavedIntList(data['floorSaveEventsClaimed']));

    randomTitleFloorRewardsClaimed
      ..clear()
      ..addAll(readSavedIntList(data['randomTitleFloorRewardsClaimed']));

    titleChoiceRoomsClaimed
      ..clear()
      ..addAll(readSavedIntList(data['titleChoiceRoomsClaimed']));

    gradeEventsSeenThisRun
      ..clear()
      ..addAll(readSavedStringList(data['gradeEventsSeenThisRun']));

    artSkillChoices
      ..clear()
      ..addAll(
        Map<String, List<String>>.from(
          ((data['artSkillChoices'] as Map?) ?? const {}).map(
            (key, value) =>
                MapEntry(key.toString(), readSavedStringList(value)),
          ),
        ),
      );

    artSkillProgress.clear();
    final restoredSkillProgress =
        (data['artSkillProgress'] as Map?) ?? const {};
    for (final entry in restoredSkillProgress.entries) {
      final progress = _ArtSkillProgress(skillId: entry.key.toString());
      progress.level = readSavedInt(entry.value);
      artSkillProgress[entry.key.toString()] = progress;
    }

    relicOpenLastFloor
      ..clear()
      ..addAll(readSavedIntMap(data['relicOpenLastFloor']));

    elementalResist
      ..clear()
      ..addAll(readSavedIntMap(data['elementalResist']));

    final restoredAttachedIds = readSavedStringList(data['attachedDropIds']);
    attachedDrops
      ..clear()
      ..addAll(
        _uniqueDrops
            .where((drop) => restoredAttachedIds.contains(drop.id))
            .map(
              (drop) => _AttachedDrop(
                dropId: drop.id,
                nameIt: drop.nameIt,
                nameEn: drop.nameEn,
                elementId: drop.elementId,
                damageBonus: drop.damageBonus,
                defenseBonus: drop.defenseBonus,
                resistBonus: drop.resistBonus,
              ),
            ),
      );

    inventoryDrops
      ..clear()
      ..addAll(
        _uniqueDrops.where(
          (drop) => ((data['inventoryDropIds'] as List?) ?? const []).contains(
            drop.id,
          ),
        ),
      );

    log
      ..clear()
      ..addAll(readSavedStringList(data['log']));

    textIt =
        data['textIt'] as String? ??
        'Run ripristinata dall’ultimo salvataggio.';
    textEn = data['textEn'] as String? ?? 'Run restored from the last save.';

    enemyHp = (data['enemyHp'] as num?)?.toInt() ?? enemyHp;
    enemyMaxHp = (data['enemyMaxHp'] as num?)?.toInt() ?? enemyMaxHp;
    enemyAttack = (data['enemyAttack'] as num?)?.toInt() ?? enemyAttack;
    enemyDefense = (data['enemyDefense'] as num?)?.toInt() ?? enemyDefense;
    enemyBleed = (data['enemyBleed'] as num?)?.toInt() ?? enemyBleed;
    enemyBurn = (data['enemyBurn'] as num?)?.toInt() ?? enemyBurn;
    enemyWeak = (data['enemyWeak'] as num?)?.toInt() ?? enemyWeak;
    playerStunTurns =
        (data['playerStunTurns'] as num?)?.toInt() ?? playerStunTurns;
    playerSlowTurns =
        (data['playerSlowTurns'] as num?)?.toInt() ?? playerSlowTurns;
    playerBurnTurns =
        (data['playerBurnTurns'] as num?)?.toInt() ?? playerBurnTurns;
    playerBleedTurns =
        (data['playerBleedTurns'] as num?)?.toInt() ?? playerBleedTurns;
    playerAttackDebuffTurns =
        (data['playerAttackDebuffTurns'] as num?)?.toInt() ??
        playerAttackDebuffTurns;
    playerDefenseDebuffTurns =
        (data['playerDefenseDebuffTurns'] as num?)?.toInt() ??
        playerDefenseDebuffTurns;
    playerAttackDebuffValue =
        (data['playerAttackDebuffValue'] as num?)?.toInt() ??
        playerAttackDebuffValue;
    playerDefenseDebuffValue =
        (data['playerDefenseDebuffValue'] as num?)?.toInt() ??
        playerDefenseDebuffValue;
    enemyIsBoss = readSavedBool(data['enemyIsBoss']);
    enemyIsElite = readSavedBool(data['enemyIsElite']);
    enemyNameIt = data['enemyNameIt'] as String? ?? enemyNameIt;
    enemyNameEn = data['enemyNameEn'] as String? ?? enemyNameEn;
    enemyElementId = data['enemyElementId'] as String? ?? enemyElementId;

    enemyParty
      ..clear()
      ..addAll(
        ((data['enemyParty'] as List?) ?? const []).whereType<Map>().map(
          (e) => enemyFromCheckpoint(Map<String, dynamic>.from(e)),
        ),
      );

    defeatedEnemyNamesIt
      ..clear()
      ..addAll(readSavedStringList(data['defeatedEnemyNamesIt']));
    defeatedEnemyNamesEn
      ..clear()
      ..addAll(readSavedStringList(data['defeatedEnemyNamesEn']));

    if (enemyParty.isNotEmpty) {
      syncPrimaryEnemyFromParty();
      inCombat = true;
    } else {
      inCombat = false;
      syncPrimaryEnemyFromParty();
    }

    choicePanelMode = data['choicePanelMode'] as String? ?? choicePanelMode;
    showEventChoices = readSavedBool(data['showEventChoices'], fallback: true);
    showCombatActions = readSavedBool(
      data['showCombatActions'],
      fallback: true,
    );
    showLogPanel = readSavedBool(data['showLogPanel']);
    showArtBoard = readSavedBool(data['showArtBoard']);
    showWeaponBoard = readSavedBool(data['showWeaponBoard']);
    showSpritePanel = readSavedBool(data['showSpritePanel'], fallback: true);
    showSpriteCodex = readSavedBool(data['showSpriteCodex']);
    classicCombatView = readSavedBool(data['classicCombatView']);
    quickEyeCollapsed = readSavedBool(data['quickEyeCollapsed']);
    playerSpriteShape =
        (data['playerSpriteShape'] as num?)?.toInt() ?? playerSpriteShape;
    playerSpriteAccent =
        (data['playerSpriteAccent'] as num?)?.toInt() ?? playerSpriteAccent;
    quickTileOrder
      ..clear()
      ..addAll(
        readSavedStringList(data['quickTileOrder']).isEmpty
            ? const [
                'party',
                'costume',
                'relic',
                'art',
                'titles',
                'bag',
                'kooba',
                'drowned',
              ]
            : readSavedStringList(data['quickTileOrder']),
      );

    textIt =
        'Il fato si ricorda di te e ti porterà all’ultimo salvataggio o alla tua ultima battaglia registrata.\n\n'
        '$textIt';
    textEn =
        'Fate remembers you and will carry you to the last save or your last recorded battle.\n\n'
        '$textEn';

    clearChoices(mode: 'event');
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Usa questo salvataggio',
        labelEn: 'Use this save',
        icon: Icons.visibility,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt =
                'Il fato ti ha riportato al ricordo inciso. Puoi proseguire.';
            textEn =
                'Fate brought you back to the engraved memory. You can continue.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Non usare il salvataggio',
        labelEn: 'Do not use the save',
        icon: Icons.visibility_off,
        color: Colors.blueGrey,
        onPressed: () => declineActiveRunCheckpoint(
          stopRun: true,
          messageIt:
              'Hai rifiutato l’ultimo salvataggio caricato.\n\n'
              'L’occhio dimentica quel ricordo. Puoi iniziare una nuova run quando vuoi.',
          messageEn:
              'You refused the loaded save.\n\n'
              'The eye forgets that memory. You can start a new run whenever you want.',
        ),
      ),
    );
  }

  Future<void> tryLoadRunCheckpoint(SharedPreferences prefs) async {
    final raw = prefs.getString('oculumDungeon.activeRunCheckpoint');
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      if (readSavedBool(decoded['gameOver'])) return;
      if (readSavedInt(decoded['playerHp'], fallback: 1) <= 0) return;

      setState(() {
        restoreRunCheckpoint(Map<String, dynamic>.from(decoded));
      });

      addLog(
        t(
          'Il fato si ricorda di te: ultimo salvataggio caricato.',
          'Fate remembers you: last save loaded.',
        ),
      );
    } catch (_) {
      await prefs.remove('oculumDungeon.activeRunCheckpoint');
    }
  }

  void applyFloorSaveBuff(String id) {
    switch (id) {
      case 'respiro_vitalium':
        addMaxHp(12 + currentFloor * 2);
        playerHp = playerMaxHp;
        break;
      case 'palpebra_scudo':
        gainPlayerShield(18 + currentFloor * 3);
        break;
      case 'obser_incisivo':
        obserInRun += 8 + currentFloor;
        break;
      case 'polvere_ascesa':
        ascensionDustInRun += 1 + currentFloor ~/ 4;
        break;
      case 'oculum_ricaricato':
        oculumMaxCharges += 1;
        oculumCharges = oculumMaxCharges;
        break;
      case 'mano_reattiva':
        reactionAvailable = true;
        dodgeCharges += 1;
        break;
      case 'lama_di_foglia':
        runDamageBonus += 2;
        runCritBonus += 3;
        break;
      case 'pelle_di_vapium':
        runDefenseBonus += 2;
        gainPlayerShield(10);
        break;
      case 'kooba_morale':
        sparklingGears += 2;
        obserInRun += 3;
        break;
      case 'eco_di_leoness':
        runHealOnExplore += 1;
        playerHp = min(playerMaxHp, playerHp + 25);
        break;
      case 'brace_asher':
        runDamageBonus += 3;
        runBoons.add('asher_save_burn');
        break;
      case 'luna_fredda':
        dungeonOculum += 1;
        runCritBonus += 5;
        break;
    }
  }

  String floorSaveBuffNameIt(String id) {
    const names = {
      'respiro_vitalium': 'Respiro di Vitalium',
      'palpebra_scudo': 'Palpebra di Scudo',
      'obser_incisivo': 'Obser Incisivo',
      'polvere_ascesa': 'Polvere d’Ascesa',
      'oculum_ricaricato': 'Oculum Ricaricato',
      'mano_reattiva': 'Mano Reattiva',
      'lama_di_foglia': 'Lama di Foglia',
      'pelle_di_vapium': 'Pelle di Vapium',
      'kooba_morale': 'Morale di Kooba',
      'eco_di_leoness': 'Eco di Leoness',
      'brace_asher': 'Brace di Asher',
      'luna_fredda': 'Luna Fredda',
    };
    return names[id] ?? id;
  }

  String floorSaveBuffNameEn(String id) {
    const names = {
      'respiro_vitalium': 'Vitalium Breath',
      'palpebra_scudo': 'Shield Eyelid',
      'obser_incisivo': 'Engraved Obser',
      'polvere_ascesa': 'Ascension Dust',
      'oculum_ricaricato': 'Recharged Oculum',
      'mano_reattiva': 'Reactive Hand',
      'lama_di_foglia': 'Leaf Blade',
      'pelle_di_vapium': 'Vapium Skin',
      'kooba_morale': 'Kooba Morals',
      'eco_di_leoness': 'Leoness Echo',
      'brace_asher': 'Asher Ember',
      'luna_fredda': 'Cold Moon',
    };
    return names[id] ?? id;
  }

  bool maybeEarlyAscensionDustFind({bool force = false}) {
    if (!runActive || gameOver || inCombat) return false;
    if (room <= 0 || room > 7) return false;
    if (earlyDustRoomsClaimed.contains(room)) return false;

    // Piccole quantità: non deve rompere l'economia, solo aiutare le primissime stanze.
    final chancePercent = force ? 100 : 38;
    if (!chance(chancePercent)) return false;

    final amount = chance(12) ? 2 : 1;
    ascensionDustInRun += amount;
    earlyDustRoomsClaimed.add(room);

    addLog(
      t(
        'Prime stanze: trovi +$amount Ascension Dust.',
        'Early rooms: you find +$amount Ascension Dust.',
      ),
    );

    textIt +=
        '\n\nTra le crepe delle prime stanze trovi una piccola polvere d’ascesa: +$amount Ascension Dust.';
    textEn +=
        '\n\nAmong the cracks of the first rooms you find a small ascension powder: +$amount Ascension Dust.';

    saveRunCheckpoint(
      reasonIt: 'Polvere d’ascesa delle prime stanze registrata.',
      reasonEn: 'Early-room ascension dust recorded.',
    );

    return true;
  }

  bool maybeFloorSaveEvent() {
    if (!runActive || gameOver || inCombat) return false;
    if (currentFloor <= 0 || currentFloor > 12) return false;
    if (floorSaveEventsClaimed.contains(currentFloor)) return false;
    if (!floorZeroCompleted && currentFloor == 0) return false;

    floorSaveEventsClaimed.add(currentFloor);

    const buffs = [
      'respiro_vitalium',
      'palpebra_scudo',
      'obser_incisivo',
      'polvere_ascesa',
      'oculum_ricaricato',
      'mano_reattiva',
      'lama_di_foglia',
      'pelle_di_vapium',
      'kooba_morale',
      'eco_di_leoness',
      'brace_asher',
      'luna_fredda',
    ];

    final buff = buffs[_random.nextInt(buffs.length)];
    applyFloorSaveBuff(buff);
    saveRunCheckpoint(
      reasonIt: 'Salvataggio evento del piano $currentFloor.',
      reasonEn: 'Floor $currentFloor event save.',
    );

    clearChoices(mode: 'event');
    textIt =
        'Evento Salvataggio — Piano $currentFloor/12.\n\n'
        'L’occhio incide un ricordo nella pietra.\n'
        'Se chiudi l’app, quando riapri il minigioco torni qui.\n'
        'Non funziona se muori: la morte spezza il ricordo.\n'
        'Puoi anche scegliere di non usare questo salvataggio.\n\n'
        'Buff casuale: ${floorSaveBuffNameIt(buff)}.';
    textEn =
        'Save Event — Floor $currentFloor/12.\n\n'
        'The eye engraves a memory into stone.\n'
        'If you close the app, when you reopen the minigame you return here.\n'
        'It does not work if you die: death breaks the memory.\n'
        'You can also choose not to use this save.\n\n'
        'Random buff: ${floorSaveBuffNameEn(buff)}.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Continua dal ricordo',
        labelEn: 'Continue from memory',
        icon: Icons.visibility,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt = 'Il ricordo resta inciso. Puoi proseguire.';
            textEn = 'The memory remains engraved. You can continue.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Non usare questo salvataggio',
        labelEn: 'Do not use this save',
        icon: Icons.visibility_off,
        color: Colors.blueGrey,
        onPressed: () => declineActiveRunCheckpoint(
          messageIt:
              'Non usi il salvataggio di questo piano.\n\n'
              'Il buff resta, ma l’occhio non ti riporterà qui se chiudi l’app.',
          messageEn:
              'You do not use this floor save.\n\n'
              'The buff remains, but the eye will not bring you back here if you close the app.',
        ),
      ),
    );

    return true;
  }

  void clearChoices({String mode = 'event'}) {
    choicePanelMode = mode;
    eventChoices.clear();
    showEventChoices = true;
  }

  void addMaxHp(int amount) {
    playerMaxHp += amount;
    playerHp = min(playerMaxHp, playerHp + amount);
  }

  bool get convertsShieldToOculumShield =>
      activeRelic?.effectId == 'oculum_shield_converter';

  int totalPlayerShieldValue() => playerShield + playerOculumShield;

  void gainPlayerShield(int amount) {
    if (amount <= 0) return;
    if (convertsShieldToOculumShield) {
      gainOculumShield(amount, expandMaximum: true);
      return;
    }
    playerShield += amount;
  }

  void setPlayerShieldAtLeast(int value) {
    final target = max(0, value);
    if (convertsShieldToOculumShield) {
      if (playerOculumShield < target) {
        gainOculumShield(target - playerOculumShield, expandMaximum: true);
      }
      playerShield = 0;
      return;
    }
    playerShield = max(playerShield, target).toInt();
  }

  void gainOculumShield(int amount, {bool expandMaximum = true}) {
    if (amount <= 0) return;
    if (expandMaximum) {
      playerOculumShieldMax = max(playerOculumShieldMax, playerOculumShield);
      playerOculumShieldMax += amount;
    } else if (playerOculumShieldMax <= 0) {
      playerOculumShieldMax = amount;
    }
    playerOculumShield = min(
      max(playerOculumShieldMax, playerOculumShield),
      playerOculumShield + amount,
    );
  }

  void refillOculumShield() {
    if (playerOculumShieldMax <= 0) return;
    playerOculumShield = playerOculumShieldMax;
  }

  void normalizeOculumShieldRelicConversion() {
    if (!convertsShieldToOculumShield || playerShield <= 0) return;
    gainOculumShield(playerShield, expandMaximum: true);
    playerShield = 0;
  }

  Map<String, int> applyPlayerDamage(
    int damage, {
    bool ignoreShields = false,
    bool ignoreNormalShield = false,
    bool ignoreOculumShield = false,
  }) {
    var remaining = max(0, damage);
    var oculumAbsorbed = 0;
    var shieldAbsorbed = 0;

    if (!ignoreShields && !ignoreOculumShield && playerOculumShield > 0) {
      oculumAbsorbed = min(playerOculumShield, remaining);
      playerOculumShield -= oculumAbsorbed;
      remaining -= oculumAbsorbed;
    }

    if (!ignoreShields && !ignoreNormalShield && playerShield > 0) {
      shieldAbsorbed = min(playerShield, remaining);
      playerShield -= shieldAbsorbed;
      remaining -= shieldAbsorbed;
    }

    final hpDamage = max(0, remaining);
    if (hpDamage > 0) {
      playerHp = max(0, playerHp - hpDamage).toInt();
      roomsWithoutDamage = 0;
    }

    return {
      'total': max(0, damage),
      'oculumShield': oculumAbsorbed,
      'shield': shieldAbsorbed,
      'hp': hpDamage,
    };
  }

  void changeDungeonKarma(int delta) {
    if (delta == 0) return;
    final previous = dungeonKarma;
    dungeonKarma += delta;
    unlockKarmaRewards(previous);
  }

  void unlockKarmaRewards(int previousKarma) {
    var changed = false;
    if (previousKarma < 6 && dungeonKarma >= 6) {
      changed = unlockedNpcIds.add('karma_split_guide') || changed;
      widget.onThemeUnlocked?.call('karma_duality');
      textIt +=
          '\n\nKarma +6: la Guida della Bilancia si ricorda di te. NPC sbloccato.';
      textEn += '\n\nKarma +6: the Scale Guide remembers you. NPC unlocked.';
    }
    if (previousKarma > -6 && dungeonKarma <= -6) {
      changed = unlockedNpcIds.add('debt_black_candle') || changed;
      widget.onThemeUnlocked?.call('karma_duality');
      textIt +=
          '\n\nKarma -6: la Candela Nera del Debito accetta di seguirti. NPC sbloccato.';
      textEn +=
          '\n\nKarma -6: the Black Debt Candle agrees to follow you. NPC unlocked.';
    }
    if (previousKarma < 12 && dungeonKarma >= 12) {
      changed = unlockedRelicIds.add('occhio_scudo_oculum') || changed;
      textIt +=
          '\n\nKarma +12: la Reliquia dello Scudo Oculum entra nelle scelte iniziali.';
      textEn +=
          '\n\nKarma +12: the Oculum Shield Relic enters starting choices.';
    }
    if (previousKarma > -12 && dungeonKarma <= -12) {
      changed = unlockedRelicIds.add('occhio_scudo_oculum') || changed;
      textIt +=
          '\n\nKarma -12: lo stesso occhio ti trova dal lato sbagliato. Reliquia sbloccata.';
      textEn +=
          '\n\nKarma -12: the same eye finds you from the wrong side. Relic unlocked.';
    }
    if (changed) _savePermanentProgress();
  }

  bool spendRunStat(String statId, int amount) {
    if (amount <= 0) return true;
    switch (statId) {
      case 'res':
        if (dungeonResilienza < amount) return false;
        dungeonResilienza -= amount;
        spentRunResilienza += amount;
        return true;
      case 'vol':
        if (dungeonVolonta < amount) return false;
        dungeonVolonta -= amount;
        spentRunVolonta += amount;
        return true;
      case 'mat':
        if (dungeonMateria < amount) return false;
        dungeonMateria -= amount;
        spentRunMateria += amount;
        return true;
      case 'ocu':
        if (dungeonOculum < amount) return false;
        dungeonOculum -= amount;
        spentRunOculum += amount;
        return true;
    }
    return false;
  }

  int _restoreSpentStat({
    required int debt,
    required bool full,
    required ValueChanged<int> apply,
  }) {
    if (debt <= 0) return 0;
    final amount = full ? debt : min(debt, max(1, (debt / 2).ceil())).toInt();
    apply(amount);
    return amount;
  }

  int restoreSpentRunStats({required bool full}) {
    var restored = 0;
    restored += _restoreSpentStat(
      debt: spentRunResilienza,
      full: full,
      apply: (amount) {
        dungeonResilienza += amount;
        spentRunResilienza -= amount;
      },
    );
    restored += _restoreSpentStat(
      debt: spentRunVolonta,
      full: full,
      apply: (amount) {
        dungeonVolonta += amount;
        spentRunVolonta -= amount;
      },
    );
    restored += _restoreSpentStat(
      debt: spentRunMateria,
      full: full,
      apply: (amount) {
        dungeonMateria += amount;
        spentRunMateria -= amount;
      },
    );
    restored += _restoreSpentStat(
      debt: spentRunOculum,
      full: full,
      apply: (amount) {
        dungeonOculum += amount;
        spentRunOculum -= amount;
      },
    );
    return restored;
  }

  String spentStatsRestoreLineIt(int restored) {
    if (restored <= 0) return '';
    return '\nStatistiche spese ripristinate: +$restored totali.';
  }

  String spentStatsRestoreLineEn(int restored) {
    if (restored <= 0) return '';
    return '\nSpent stats restored: +$restored total.';
  }

  List<_StarterWeapon> availableStartingWeapons() {
    return _starterWeapons
        .where(
          (w) =>
              (w.unlockedByDefault || unlockedWeaponIds.contains(w.id)) &&
              canShowStoryLockedWeapon(w.id),
        )
        .toList();
  }

  List<_StarterWeapon> randomStartingWeaponChoices() {
    final weapons = List<_StarterWeapon>.from(availableStartingWeapons());
    weapons.shuffle(_random);
    return weapons.take(3).toList();
  }

  List<_DungeonArt> availableStartingArts() {
    return _allArts
        .where(
          (a) =>
              isArtUnlockableOutsideLateGame(a) ||
              (isVillageLockedArtId(a.effectId) &&
                  unlockedArtIds.contains(a.effectId)),
        )
        .where(
          (a) => a.unlockedByDefault || unlockedArtIds.contains(a.effectId),
        )
        .toList();
  }

  List<String> ensureThreeRandomSkillsForArt(_DungeonArt art) {
    final existing = artSkillChoices[art.effectId];
    if (existing != null && existing.length == 3) {
      final repaired = List<String>.from(existing);
      var changed = false;

      if (art.elementId == 'water') {
        final drownedId = '${art.effectId}_skill_04';
        if (!repaired.contains(drownedId)) {
          repaired[repaired.length - 1] = drownedId;
          changed = true;
        }
      }

      if (art.elementId == 'flora') {
        final thornId = '${art.effectId}_thorn_whip';
        if (!repaired.contains(thornId)) {
          repaired[0] = thornId;
          changed = true;
        }
      }

      if (changed) {
        artSkillChoices[art.effectId] = repaired;
        for (final skillId in repaired) {
          artSkillProgress.putIfAbsent(
            skillId,
            () => _ArtSkillProgress(skillId: skillId),
          );
        }
      }

      return repaired;
    }

    final pool = buildArtSkillPool(art)..shuffle(_random);
    final picked = <String>[];

    if (art.elementId == 'flora') {
      final thorn = pool
          .where((s) => s.id == '${art.effectId}_thorn_whip')
          .toList();
      if (thorn.isNotEmpty) picked.add(thorn.first.id);
    }

    if (art.elementId == 'water') {
      final drownedChain = pool
          .where((s) => s.id == '${art.effectId}_skill_04')
          .toList();
      if (drownedChain.isNotEmpty && !picked.contains(drownedChain.first.id)) {
        picked.add(drownedChain.first.id);
      }
    }

    for (final skill in pool) {
      if (picked.length >= 3) break;
      if (!picked.contains(skill.id)) picked.add(skill.id);
    }
    artSkillChoices[art.effectId] = picked;
    for (final skillId in picked) {
      artSkillProgress.putIfAbsent(
        skillId,
        () => _ArtSkillProgress(skillId: skillId),
      );
    }
    return picked;
  }

  int skillLevel(String skillId) => artSkillProgress[skillId]?.level ?? 0;
  bool skillUnlocked(String skillId) => skillLevel(skillId) > 0;
  bool isDefiledArtSkillId(String skillId) =>
      skillId.startsWith('defiled_postea_art_');
  int artSkillMaxLevel(String skillId) => isDefiledArtSkillId(skillId) ? 5 : 3;
  bool skillFullyUpgraded(String skillId) =>
      skillLevel(skillId) >= artSkillMaxLevel(skillId);

  bool isThornWhipSkill(String skillId) => skillId.endsWith('_thorn_whip');

  bool canUseThornWhipII(String skillId) =>
      isThornWhipSkill(skillId) &&
      skillLevel(skillId) >= 2 &&
      evonestProof >= 1;

  String thornWhipLevelLabel(String skillId) {
    final lvl = skillLevel(skillId);
    if (lvl <= 0) return t('Bloccata', 'Locked');
    if (lvl == 1) return t('I • 6m', 'I • 6m');
    if (evonestProof <= 0) {
      return t(
        'II sigillata: parla con un Eiva',
        'II sealed: speak with an Eiva',
      );
    }
    return t('II • Eiva ascoltato', 'II • Eiva heard');
  }

  String skillLevelLabel(String skillId) {
    if (isThornWhipSkill(skillId)) return thornWhipLevelLabel(skillId);
    final lvl = skillLevel(skillId).clamp(0, artSkillMaxLevel(skillId)).toInt();
    if (lvl <= 0) return t('Bloccata', 'Locked');
    const roman = ['', 'I', 'II', 'III', 'IV', 'V'];
    return t('Forma ${roman[lvl]}', 'Form ${roman[lvl]}');
  }

  List<_ArtSkillDef> buildArtSkillPool(_DungeonArt art) {
    final prefix = art.effectId;
    if (prefix == 'modern_school_art') {
      return [
        _ArtSkillDef(
          id: '${prefix}_non_newtonian_liquid',
          nameIt: 'Chimica servirà pur a qualcosa',
          nameEn: 'Chemistry Must Be Useful Somehow',
          descIt:
              'Forma I: spendi 1-3 Oculum e crei un liquido non newtoniano: +Resilienza, Scudo e danni.\n'
              'Forma II: il liquido si irrigidisce sui colpi e rallenta il nemico.\n'
              'Forma III: diventa una corazza reattiva che assorbe danni e li restituisce.',
          descEn:
              'Form I: spend 1-3 Oculum to create a non-Newtonian liquid: +Resilience, Shield and damage.\n'
              'Form II: the liquid hardens on impact and slows the enemy.\n'
              'Form III: it becomes reactive armor that absorbs damage and returns it.',
          kind: 'defense',
        ),
        _ArtSkillDef(
          id: '${prefix}_useful_physical_activity',
          nameIt: 'Attività fisica dimostrati utile!',
          nameEn: 'Physical Education, Prove Useful!',
          descIt:
              'Forma I: spendi 1-3 Oculum e ti buffi di Oculum alle stats.\n'
              'Forma II: il buff aumenta e prepara una reazione atletica.\n'
              'Forma III: il corpo tiene il ritmo: più stats, schivata e critico.',
          descEn:
              'Form I: spend 1-3 Oculum and buff your stats by Oculum.\n'
              'Form II: the buff grows and prepares an athletic reaction.\n'
              'Form III: your body keeps pace: more stats, dodge and critical.',
          kind: 'utility',
        ),
        _ArtSkillDef(
          id: '${prefix}_time_math',
          nameIt: 'La Matematica Del Tempo',
          nameEn: 'The Mathematics of Time',
          descIt:
              'Forma I: morendo torni indietro una volta ogni 6 stanze all ultima azione con +3.\n'
              'Forma II: il ritorno conserva più HP e dà Scudo.\n'
              'Forma III: il calcolo anticipa la morte: +3 diventa +6 e ricarica Oculum.',
          descEn:
              'Form I: on death, rewind once every 6 rooms to the last action with +3.\n'
              'Form II: the rewind preserves more HP and grants Shield.\n'
              'Form III: the calculation predicts death: +3 becomes +6 and restores Oculum.',
          kind: 'special',
        ),
      ];
    }
    if (prefix == 'kingi_blue_art') {
      return [
        _ArtSkillDef(
          id: '${prefix}_blue_control',
          nameIt: 'Controllo del Blu',
          nameEn: 'Blue Control',
          descIt:
              'Forma I: investi 1-5 Oculum. Aumenti la tua Materia di 5+Oculum; se l avversario manca sembrerà di colpirti e hai +3 per colpirlo.\n'
              'Forma II: investi 6-20 Oculum. Materia +10+Oculumx3, +6 per colpirlo e +5 danni da fuoco.\n'
              'Forma III: investi 12-30 Oculum. Il falso impatto diventa esca blu: +9 per colpire, fuoco e fulmine insieme.',
          descEn:
              'Form I: invest 1-5 Oculum. Gain Materia 5+Oculum; if the enemy misses it seems to hit you and you gain +3 to hit it.\n'
              'Form II: invest 6-20 Oculum. Materia +10+Oculumx3, +6 to hit and +5 fire damage.\n'
              'Form III: invest 12-30 Oculum. The fake impact becomes blue bait: +9 to hit, fire and lightning together.',
          kind: 'control',
        ),
        _ArtSkillDef(
          id: '${prefix}_flaming_form',
          nameIt: 'Forma Fiammeggiante',
          nameEn: 'Flaming Form',
          descIt:
              'Forma I: costa 5 Oculum. +3 Volontà, +2 Materia, +10 difesa e danni per 6 turni.\n'
              'Forma II: costa 8 Oculum. +6 Volontà, +4 Materia, +15 difesa e danni per 10 turni.\n'
              'Forma III: costa 12 Oculum. +9 Volontà, +6 Materia, +22 difesa e danni; le fiamme diventano blu scuro.',
          descEn:
              'Form I: costs 5 Oculum. +3 Will, +2 Materia, +10 defense and damage for 6 turns.\n'
              'Form II: costs 8 Oculum. +6 Will, +4 Materia, +15 defense and damage for 10 turns.\n'
              'Form III: costs 12 Oculum. +9 Will, +6 Materia, +22 defense and damage; flames turn dark blue.',
          kind: 'special',
        ),
        _ArtSkillDef(
          id: '${prefix}_lightning_form',
          nameIt: 'Forma Fulminea',
          nameEn: 'Lightning Form',
          descIt:
              'Forma I: costa 3 Oculum e richiede Forma Fiammeggiante. Per Oculum turni hai una reazione in più, +6 Materia e +9 Volontà.\n'
              'Forma II: costa 20 Oculum. Azione gratuita al primo turno, reazione extra e +20 danni o +20 difesa su quella reazione, +36 Materia e +51 Volontà.\n'
              'Forma III: costa 30 Oculum. Le fiamme diventano fulmini stabili: reazioni blu, danni ad area e Scudo a ogni scarica.',
          descEn:
              'Form I: costs 3 Oculum and requires Flaming Form. For Oculum turns you gain one extra reaction, +6 Materia and +9 Will.\n'
              'Form II: costs 20 Oculum. Free action on the first turn, extra reaction and +20 damage or +20 defense on that reaction, +36 Materia and +51 Will.\n'
              'Form III: costs 30 Oculum. Flames become stable lightning: blue reactions, area damage and Shield on each discharge.',
          kind: 'damage',
        ),
      ];
    }
    if (prefix == 'defiled_postea_art') {
      return [
        _ArtSkillDef(
          id: '${prefix}_runic_guards',
          nameIt: 'Guardie Runiche di Postea',
          nameEn: 'Postea Runic Guards',
          descIt:
              'Forma I-V: spendi da 1 a 6 kg di Metallo Runico Postea. Evochi due guardie runiche di metà livello con Resilienza 5+10xkg, Volontà 25+5xkg, Materia 25+5xkg e +50 danni da esplosione a morte.',
          descEn:
              'Form I-V: spend 1 to 6 kg of Postea Runic Metal. Summon two half-level runic guards with Resilience 5+10xkg, Will 25+5xkg, Materia 25+5xkg and +50 death explosion damage.',
          kind: 'special',
        ),
        _ArtSkillDef(
          id: '${prefix}_fast_upgrade',
          nameIt: 'Potenziamento Veloce',
          nameEn: 'Fast Upgrade',
          descIt:
              'Forma I: spendi 1-5 Obser, +1 a tutte le stats per Obser speso.\n'
              'Forma II: spendi 4-6 Obser, +2 a tutte le stats per Obser speso.\n'
              'Forma III: spendi 6-9 Obser, +3 a tutte le stats e Scudo.\n'
              'Forma IV: spendi 8-12 Obser, +4 a tutte le stats e reazione pronta.\n'
              'Forma V: spendi 10-15 Obser, +5 a tutte le stats, critico e Oculum. La prima volta in giornata è azione gratuita.',
          descEn:
              'Form I: spend 1-5 Obser, +1 to all stats per Obser spent.\n'
              'Form II: spend 4-6 Obser, +2 to all stats per Obser spent.\n'
              'Form III: spend 6-9 Obser, +3 to all stats and Shield.\n'
              'Form IV: spend 8-12 Obser, +4 to all stats and ready reaction.\n'
              'Form V: spend 10-15 Obser, +5 to all stats, critical and Oculum. First daily use is a free action.',
          kind: 'utility',
        ),
        _ArtSkillDef(
          id: '${prefix}_defensive_aura',
          nameIt: 'Aura Difensiva',
          nameEn: 'Defensive Aura',
          descIt:
              'Forma I: costa 5 Oculum, cooldown 3 azioni. Immetti su te o altri 5+Oculumx3 difesa da fuoco.\n'
              'Forma II: costa 7 Oculum, più Scudo e resistenza al fuoco.\n'
              'Forma III: costa 9 Oculum, protegge anche da esplosione.\n'
              'Forma IV: costa 11 Oculum, estende l aura agli alleati.\n'
              'Forma V: costa 13 Oculum, converte parte del fuoco assorbito in danno Postea.',
          descEn:
              'Form I: costs 5 Oculum, 3-action cooldown. Give yourself or others 5+Oculumx3 fire defense.\n'
              'Form II: costs 7 Oculum, more Shield and fire resistance.\n'
              'Form III: costs 9 Oculum, also protects from explosion.\n'
              'Form IV: costs 11 Oculum, extends the aura to allies.\n'
              'Form V: costs 13 Oculum, converts part of absorbed fire into Postea damage.',
          kind: 'defense',
        ),
      ];
    }
    if (prefix == 'hoshy_oculum_art') {
      return [
        _ArtSkillDef(
          id: '${prefix}_stelle_comete',
          nameIt: 'Stelle Comete',
          nameEn: 'Comet Stars',
          descIt:
              'Lvl I: lanci l Oculum immesso in piccole stelle comete: Volontà +2 danni.\n'
              'Lvl II: le stelle crescono: Volontà +4 danni.\n'
              'Lvl III: le comete diventano Frammenti Emblema: Volontà +8 danni e +Fragilità.',
          descEn:
              'Lvl I: throw the invested Oculum as small comet stars: Will +2 damage.\n'
              'Lvl II: the stars grow: Will +4 damage.\n'
              'Lvl III: comets become Emblem Shards: Will +8 damage and +Fragility.',
          kind: 'damage',
        ),
        _ArtSkillDef(
          id: '${prefix}_esplosione_contatto',
          nameIt: 'Esplosione a Contatto',
          nameEn: 'Contact Burst',
          descIt:
              'Lvl I: provochi un esplosione sulla pelle: danno ad area pari al doppio della Difesa.\n'
              'Lvl II: la chiave ad S stabilizza l esplosione: area maggiore e -Difesa nemica.\n'
              'Lvl III: la detonazione lascia Scudo stellare dopo il danno.',
          descEn:
              'Lvl I: trigger an explosion on your skin: area damage equal to double Defense.\n'
              'Lvl II: the S key stabilizes the burst: wider area and enemy -Defense.\n'
              'Lvl III: the detonation leaves stellar Shield after damage.',
          kind: 'special',
        ),
        _ArtSkillDef(
          id: '${prefix}_forma_stellare',
          nameIt: 'Forma Stellare',
          nameEn: 'Stellar Form',
          descIt:
              'Lvl I: per turni pari all Oculum immesso ti trasformi: voli, CM aumenta del doppio dell Oculum immesso e VC aumenta dello stesso valore senza raddoppio.\n'
              'Lvl II: dopo 5 Plump la forma tiene meglio: più schivate e Scudo.\n'
              'Lvl III: forma stellare completa, con critico e Oculum ricaricato.',
          descEn:
              'Lvl I: for turns equal to invested Oculum you transform: you fly, CM rises by twice the invested Oculum and VC rises by the same value without doubling.\n'
              'Lvl II: after 5 Plump kills the form holds better: more dodges and Shield.\n'
              'Lvl III: complete stellar form, with critical and restored Oculum.',
          kind: 'defense',
        ),
      ];
    }
    if (prefix == 'autumn_oculum_art') {
      return [
        _ArtSkillDef(
          id: '${prefix}_tempest_falling_leaves',
          nameIt: 'Tempest of the Falling Leaves',
          nameEn: 'Tempest of the Falling Leaves',
          descIt:
              'I: tornado di foglie secche e vento, danni Oculum ad area.\nII: aggiunge Rinsecchito e avvicina tutti i nemici.',
          descEn:
              'I: dry leaf and wind tornado, Oculum area damage.\nII: adds Withered and pulls all enemies close.',
          kind: 'damage',
        ),
        _ArtSkillDef(
          id: '${prefix}_death_birth',
          nameIt: 'Dalla Morte Nasce Sempre Qualcosa',
          nameEn: 'From Death Something Always Grows',
          descIt:
              'Ogni 3 Oculum spesi in questa skill si convertono in +1 Materia della run.',
          descEn:
              'Every 3 Oculum spent on this skill convert into +1 run Materia.',
          kind: 'utility',
        ),
        _ArtSkillDef(
          id: '${prefix}_autumn_regeneration',
          nameIt: 'Rigenerazione Dell Autunno',
          nameEn: 'Autumn Regeneration',
          descIt:
              'Prima azione del turno: rigenera 1-3 Oculum in area ventosa, ma prendi svantaggio per il turno.',
          descEn:
              'First action of the turn: regenerates 1-3 Oculum in windy area, but gives disadvantage for the turn.',
          kind: 'special',
        ),
      ];
    }
    if (prefix == 'swiftness_martial_art') {
      return [
        _ArtSkillDef(
          id: '${prefix}_chain_damage',
          nameIt: 'Chain Damage',
          nameEn: 'Chain Damage',
          descIt:
              'Tiri 1d6 colpi su massimo quel risultato di nemici. Ogni colpo fa danni dimezzati. Costa 2 Materia e ti da +5 danni per il turno.',
          descEn:
              'Roll 1d6 hits across up to that many enemies. Each hit deals halved damage. Costs 2 Materia and grants +5 damage this turn.',
          kind: 'damage',
        ),
        _ArtSkillDef(
          id: '${prefix}_vanish_tp',
          nameIt: 'Vanish TP',
          nameEn: 'Vanish TP',
          descIt:
              'Schivi 1d4 colpi, -1 per ogni Grado avversario sopra il tuo. Costa 3 Materia o Volontà.',
          descEn:
              'Dodge 1d4 hits, -1 per enemy Grade above yours. Costs 3 Materia or Will.',
          kind: 'defense',
        ),
        _ArtSkillDef(
          id: '${prefix}_critical_flow',
          nameIt: 'Flusso Critico',
          nameEn: 'Critical Flow',
          descIt:
              'Effetto marziale passivo: i critici creano concatenazioni e fragilita.',
          descEn: 'Martial passive: critical hits create chains and fragility.',
          kind: 'special',
        ),
      ];
    }
    switch (art.elementId) {
      case 'fire':
        return _canonicalSkills(
          prefix,
          'Scintilla Funebre',
          'Funeral Spark',
          'Muro di Brace',
          'Ember Wall',
          'Cauterio Vivo',
          'Living Cautery',
          'Fumo negli Occhi',
          'Smoke in the Eyes',
          'Occhio del Braciere',
          'Brazier Eye',
          'Morso di Fiamma',
          'Flame Bite',
          'Pelle Carbonizzata',
          'Charred Skin',
          'Risveglio dell’Incendio',
          'Inferno Awakening',
          'damage',
        );
      case 'wind':
        return _canonicalSkills(
          prefix,
          'Taglio del Vento',
          'Wind Cut',
          'Guardia del Respiro',
          'Breath Guard',
          'Sospiro Curativo',
          'Healing Sigh',
          'Catena d’Aria',
          'Air Chain',
          'Occhio della Corrente',
          'Current Eye',
          'Morso della Raffica',
          'Gust Bite',
          'Pelle Leggera',
          'Light Skin',
          'Risveglio del Ciclone',
          'Cyclone Awakening',
          'control',
        );
      case 'water':
        return _canonicalSkills(
          prefix,
          'Lama di Marea',
          'Tide Blade',
          'Guardia Liquida',
          'Liquid Guard',
          'Bacio della Lacrima',
          'Tear Kiss',
          'Catena d’Annegamento',
          'Drowning Chain',
          'Occhio della Pozza',
          'Pool Eye',
          'Morso dell’Abisso',
          'Abyss Bite',
          'Pelle di Pioggia',
          'Rain Skin',
          'Risveglio del Diluvio',
          'Flood Awakening',
          'heal',
        );
      case 'earth':
        return _canonicalSkills(
          prefix,
          'Pugno di Pietra',
          'Stone Fist',
          'Muro della Radice',
          'Root Wall',
          'Respiro del Terriccio',
          'Soil Breath',
          'Catena Tettonica',
          'Tectonic Chain',
          'Occhio della Roccia',
          'Rock Eye',
          'Morso del Sottosuolo',
          'Underground Bite',
          'Pelle di Creta',
          'Clay Skin',
          'Risveglio della Frana',
          'Landslide Awakening',
          'defense',
        );
      case 'ice':
        return _canonicalSkills(
          prefix,
          'Ago di Ghiaccio',
          'Ice Needle',
          'Guardia del Vetro Freddo',
          'Cold Glass Guard',
          'Respiro Gelido',
          'Frozen Breath',
          'Catena del Torpore',
          'Numbness Chain',
          'Occhio della Brina',
          'Frost Eye',
          'Morso della Neve Sporca',
          'Dirty Snow Bite',
          'Pelle del Gelo',
          'Frost Skin',
          'Risveglio del Bianco Muto',
          'Mute White Awakening',
          'control',
        );
      case 'sound':
        return _canonicalSkills(
          prefix,
          'Urlo Cucito',
          'Sewn Scream',
          'Guardia dell’Eco',
          'Echo Guard',
          'Ninna Nanna Rotta',
          'Broken Lullaby',
          'Catena di Risonanza',
          'Resonance Chain',
          'Occhio del Rumore',
          'Noise Eye',
          'Morso della Nota Storta',
          'Crooked Note Bite',
          'Pelle Vibrante',
          'Vibrating Skin',
          'Risveglio del Coro Vuoto',
          'Empty Choir Awakening',
          'special',
        );
      case 'psyche':
        return _canonicalSkills(
          prefix,
          'Pensiero a Lama',
          'Blade Thought',
          'Guardia del Trauma',
          'Trauma Guard',
          'Carezza della Memoria',
          'Memory Caress',
          'Catena d’Ansia',
          'Anxiety Chain',
          'Occhio del Sospetto',
          'Suspicion Eye',
          'Morso del Panico',
          'Panic Bite',
          'Pelle Dissociata',
          'Dissociated Skin',
          'Risveglio della Psiche Nera',
          'Black Psyche Awakening',
          'control',
        );
      case 'lava':
        return _canonicalSkills(
          prefix,
          'Colata sul Cuore',
          'Heartflow',
          'Guardia Magmatica',
          'Magma Guard',
          'Cauterio di Lava',
          'Lava Cautery',
          'Catena Fusa',
          'Molten Chain',
          'Occhio del Cratere',
          'Crater Eye',
          'Morso del Magma',
          'Magma Bite',
          'Pelle di Basalto',
          'Basalt Skin',
          'Risveglio del Vulcano Cieco',
          'Blind Volcano Awakening',
          'damage',
        );
      case 'lightning':
        return _canonicalSkills(
          prefix,
          'Spasmo Celeste',
          'Sky Spasm',
          'Guardia Statica',
          'Static Guard',
          'Impulso Cardiaco',
          'Heart Impulse',
          'Catena Folgorante',
          'Shocking Chain',
          'Occhio della Tempesta',
          'Storm Eye',
          'Morso del Tuono',
          'Thunder Bite',
          'Pelle Elettrica',
          'Electric Skin',
          'Risveglio della Folgore',
          'Lightning Awakening',
          'damage',
        );
      case 'poison':
        return _canonicalSkills(
          prefix,
          'Bacio Tossico',
          'Toxic Kiss',
          'Guardia Antidoto',
          'Antidote Guard',
          'Respiro Amaro',
          'Bitter Breath',
          'Catena di Nausea',
          'Nausea Chain',
          'Occhio del Veleno',
          'Poison Eye',
          'Morso Verde',
          'Green Bite',
          'Pelle Marcia',
          'Rotten Skin',
          'Risveglio della Piaga Dolce',
          'Sweet Plague Awakening',
          'damage',
        );
      case 'flora':
        return [
          _ArtSkillDef(
            id: '${prefix}_thorn_whip',
            nameIt: 'Frusta di Spine',
            nameEn: 'Thorn Whip',
            descIt:
                'I: crei una frusta di spine lunga fino a 6 metri, come arto in più. '
                '+1 ai roll se utile alla scena e +danno pari a 3 + Oculum. '
                'II: dopo aver parlato con un Eiva la frusta si divide in spine guida, spezza guardia e tira i nemici verso di te.',
            descEn:
                'I: create a thorn whip up to 6 meters long, like an extra limb. '
                '+1 to rolls when useful to the scene and +damage equal to 3 + Oculum. '
                'II: after speaking with an Eiva the whip splits into guiding thorns, breaks guard and pulls enemies toward you.',
            kind: 'utility',
          ),
          ..._canonicalSkills(
            prefix,
            'Morso di Rovi',
            'Briar Bite',
            'Guardia del Ramo',
            'Branch Guard',
            'Linfa Cucita',
            'Sewn Sap',
            'Radici alle Caviglie',
            'Roots at the Ankles',
            'Occhio del Sottobosco',
            'Undergrowth Eye',
            'Morso di Radice',
            'Root Bite',
            'Pelle di Corteccia',
            'Bark Skin',
            'Risveglio della Selva Cieca',
            'Blind Grove Awakening',
            'control',
          ),
        ];
      case 'blood':
        return _canonicalSkills(
          prefix,
          'Taglio Venoso',
          'Vein Cut',
          'Guardia del Coagulo',
          'Clot Guard',
          'Trasfusione Nera',
          'Black Transfusion',
          'Catena Arteriosa',
          'Arterial Chain',
          'Occhio del Battito',
          'Pulse Eye',
          'Morso Ematico',
          'Blood Bite',
          'Pelle Pulsante',
          'Pulsing Skin',
          'Risveglio del Sangue Antico',
          'Ancient Blood Awakening',
          'heal',
        );
      case 'gravity':
        return _canonicalSkills(
          prefix,
          'Caduta Verso l’Alto',
          'Upward Fall',
          'Guardia Orbitale',
          'Orbital Guard',
          'Respiro Pesante',
          'Heavy Breath',
          'Catena del Peso',
          'Weight Chain',
          'Occhio del Centro',
          'Center Eye',
          'Morso della Massa',
          'Mass Bite',
          'Pelle Orbitante',
          'Orbiting Skin',
          'Risveglio della Luna Schiacciata',
          'Crushed Moon Awakening',
          'special',
        );
      case 'nullum':
        return _canonicalSkills(
          prefix,
          'Taglio Assente',
          'Absent Cut',
          'Guardia del Vuoto',
          'Void Guard',
          'Respiro Cancellato',
          'Erased Breath',
          'Catena Senza Nome',
          'Nameless Chain',
          'Occhio Null',
          'Null Eye',
          'Morso Mancante',
          'Missing Bite',
          'Pelle Senza Storia',
          'Storyless Skin',
          'Risveglio del Nulla',
          'Null Awakening',
          'special',
        );
      default:
        final e = elementDef(art.elementId);
        return _canonicalSkills(
          prefix,
          'Colpo di ${e.nameIt}',
          '${e.nameEn} Strike',
          'Guardia di ${e.nameIt}',
          '${e.nameEn} Guard',
          'Respiro di ${e.nameIt}',
          '${e.nameEn} Breath',
          'Catena di ${e.nameIt}',
          '${e.nameEn} Chain',
          'Occhio di ${e.nameIt}',
          '${e.nameEn} Eye',
          'Morso di ${e.nameIt}',
          '${e.nameEn} Bite',
          'Pelle di ${e.nameIt}',
          '${e.nameEn} Skin',
          'Risveglio di ${e.nameIt}',
          '${e.nameEn} Awakening',
          'damage',
        );
    }
  }

  List<_ArtSkillDef> _canonicalSkills(
    String prefix,
    String strikeIt,
    String strikeEn,
    String guardIt,
    String guardEn,
    String healIt,
    String healEn,
    String controlIt,
    String controlEn,
    String eyeIt,
    String eyeEn,
    String biteIt,
    String biteEn,
    String skinIt,
    String skinEn,
    String awakeningIt,
    String awakeningEn,
    String favoredKind,
  ) {
    return [
      _ArtSkillDef(
        id: '${prefix}_skill_01',
        nameIt: strikeIt,
        nameEn: strikeEn,
        descIt:
            'Lvl I: colpo elementale rapido. Lvl II: più pressione e danno. Lvl III: il colpo diventa una firma stabile.',
        descEn:
            'Lvl I: quick elemental strike. Lvl II: more pressure and damage. Lvl III: the strike becomes a stable signature.',
        kind: 'damage',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_02',
        nameIt: guardIt,
        nameEn: guardEn,
        descIt:
            'Lvl I: difesa elementale. Lvl II: più Scudo e reazione. Lvl III: la guardia lascia resistenza nella pelle.',
        descEn:
            'Lvl I: elemental defense. Lvl II: more Shield and reaction. Lvl III: the guard leaves resistance in the skin.',
        kind: 'defense',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_03',
        nameIt: healIt,
        nameEn: healEn,
        descIt:
            'Lvl I: cura o stabilizza. Lvl II: cura maggiore. Lvl III: lascia una piccola rigenerazione di run.',
        descEn:
            'Lvl I: heal or stabilize. Lvl II: stronger heal. Lvl III: leaves a small run regeneration.',
        kind: 'heal',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_04',
        nameIt: controlIt,
        nameEn: controlEn,
        descIt:
            'Lvl I: controlla ritmo, distanza o debolezza. Lvl II: apre tecniche CM. Lvl III: applica pressione anche ai mini-boss.',
        descEn:
            'Lvl I: controls rhythm, distance or weakness. Lvl II: opens CM techniques. Lvl III: applies pressure even to mini-bosses.',
        kind: 'control',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_05',
        nameIt: eyeIt,
        nameEn: eyeEn,
        descIt:
            'Lvl I: legge la stanza e manipola risorse. Lvl II: ricarica Oculum. Lvl III: apre una tecnica ad area CM.',
        descEn:
            'Lvl I: reads the room and manipulates resources. Lvl II: restores Oculum. Lvl III: opens a CM area technique.',
        kind: 'utility',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_06',
        nameIt: biteIt,
        nameEn: biteEn,
        descIt:
            'Lvl I: morso aggressivo. Lvl II: ferisce la difesa. Lvl III: lascia un effetto secondario più forte.',
        descEn:
            'Lvl I: aggressive bite. Lvl II: wounds defense. Lvl III: leaves a stronger secondary effect.',
        kind: 'damage',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_07',
        nameIt: skinIt,
        nameEn: skinEn,
        descIt:
            'Lvl I: pelle elementale. Lvl II: più Scudo. Lvl III: resistenza stabile fino a fine fight.',
        descEn:
            'Lvl I: elemental skin. Lvl II: more Shield. Lvl III: stable resistance until fight end.',
        kind: 'defense',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_08',
        nameIt: awakeningIt,
        nameEn: awakeningEn,
        descIt:
            'Lvl I: risveglio raro. Lvl II: apre area VC. Lvl III: piega il Fato e protegge la prossima stanza.',
        descEn:
            'Lvl I: rare awakening. Lvl II: opens VC area. Lvl III: bends Fate and protects the next room.',
        kind: 'special',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_09',
        nameIt: 'Lacrima Offensiva di $strikeIt',
        nameEn: '$strikeEn Offensive Tear',
        descIt:
            'Lvl I: l Oculum ripete il colpo come una lacrima tagliente. Lvl II: cerca il punto debole. Lvl III: diventa una frattura del Fato.',
        descEn:
            'Lvl I: Oculum repeats the strike as a cutting tear. Lvl II: it hunts the weak point. Lvl III: it becomes a Fate fracture.',
        kind: favoredKind == 'damage' ? 'special' : 'damage',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_10',
        nameIt: 'Bastione Vivo di $guardIt',
        nameEn: '$guardEn Living Bastion',
        descIt:
            'Lvl I: la guardia diventa un guscio vivo. Lvl II: il guscio risponde ai colpi. Lvl III: la difesa resta dopo la reazione.',
        descEn:
            'Lvl I: the guard becomes a living shell. Lvl II: the shell answers hits. Lvl III: defense remains after the reaction.',
        kind: favoredKind == 'defense' ? 'special' : 'defense',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_11',
        nameIt: 'Nodo Cieco di $controlIt',
        nameEn: '$controlEn Blind Knot',
        descIt:
            'Lvl I: lega il ritmo del nemico. Lvl II: apre tecnica CM. Lvl III: rallenta anche creature corazzate o deformi.',
        descEn:
            'Lvl I: binds the enemy rhythm. Lvl II: opens CM technique. Lvl III: slows armored or deformed creatures too.',
        kind: favoredKind == 'control' ? 'special' : 'control',
      ),
      _ArtSkillDef(
        id: '${prefix}_skill_12',
        nameIt: 'Emblema Finale di $awakeningIt',
        nameEn: '$awakeningEn Final Emblem',
        descIt:
            'Lvl I: emblema instabile. Lvl II: apre area VC e area CM. Lvl III: forma alta, rara, da boss.',
        descEn:
            'Lvl I: unstable emblem. Lvl II: opens VC and CM area. Lvl III: high, rare, boss-grade form.',
        kind: 'special',
      ),
    ];
  }

  _ArtSkillDef? findArtSkillDef(String skillId) {
    for (final art in _allArts) {
      for (final skill in buildArtSkillPool(art)) {
        if (skill.id == skillId) return skill;
      }
    }
    return null;
  }

  String buildArtSkillSummaryText() {
    if (activeArt == null) return 'Skill Oculum: —';
    final skillIds = artSkillChoices[activeArt!.effectId] ?? [];
    if (skillIds.isEmpty) return 'Skill Oculum: —';

    return 'Skill Oculum: ${skillIds.map((id) {
      final skill = findArtSkillDef(id);
      final name = widget.linguaInglese ? skill?.nameEn ?? id : skill?.nameIt ?? id;
      return '$name (${skillLevelLabel(id)})';
    }).join(' • ')}';
  }

  List<String> unlockedActiveArtSkillIds() {
    if (activeArt == null) return [];
    final ids = artSkillChoices[activeArt!.effectId] ?? [];
    return ids.where(skillUnlocked).toList();
  }

  bool hasUnlockedArtSkillKind(String kind) {
    for (final id in unlockedActiveArtSkillIds()) {
      if (findArtSkillDef(id)?.kind == kind) return true;
    }
    return false;
  }

  int activeArtSkillDamageBonus() {
    int bonus = 0;
    for (final id in unlockedActiveArtSkillIds()) {
      final skill = findArtSkillDef(id);
      final lvl = skillLevel(id);
      if (skill?.kind == 'damage') bonus += lvl * 2;
      if (skill?.kind == 'special') bonus += lvl;
    }
    return bonus;
  }

  int activeArtSkillDefenseBonus() {
    int bonus = 0;
    for (final id in unlockedActiveArtSkillIds()) {
      final skill = findArtSkillDef(id);
      final lvl = skillLevel(id);
      if (skill?.kind == 'defense') bonus += lvl * 2;
    }
    return bonus;
  }

  int skillEventBonus(String eventId) {
    int bonus = 0;
    if (eventId == 'treasure' && hasUnlockedArtSkillKind('utility')) bonus += 2;
    if (eventId == 'trap' && hasUnlockedArtSkillKind('control')) bonus += 3;
    if (eventId == 'combat' && hasUnlockedArtSkillKind('damage')) bonus += 2;
    if (eventId == 'rest' && hasUnlockedArtSkillKind('heal')) bonus += 3;
    if (eventId == 'boss' && hasUnlockedArtSkillKind('special')) bonus += 3;
    if (eventId == 'defense' && hasUnlockedArtSkillKind('defense')) bonus += 3;
    return bonus;
  }

  void progressSkillQuest({int amount = 1}) {
    if (activeSkillQuestId.isEmpty || activeSkillQuestTargetSkillId.isEmpty) {
      return;
    }
    activeSkillQuestProgress += amount;
    if (activeSkillQuestProgress >= activeSkillQuestGoal) {
      completeSkillQuest();
    }
  }

  void generateNextSkillQuest() {
    if (activeArt == null) return;
    final ids = ensureThreeRandomSkillsForArt(activeArt!);
    final available = ids.where((id) => !skillFullyUpgraded(id)).toList();

    if (available.isEmpty) {
      activeSkillQuestIt = 'Tutte le Skill Oculum scelte sono al massimo.';
      activeSkillQuestEn = 'All chosen Oculum Skills are maxed.';
      activeSkillQuestId = '';
      activeSkillQuestTargetSkillId = '';
      activeSkillQuestProgress = 0;
      activeSkillQuestGoal = 0;
      return;
    }

    available.shuffle(_random);
    final target = available.first;
    final lvl = skillLevel(target);
    final skill = findArtSkillDef(target);

    activeSkillQuestTargetSkillId = target;
    activeSkillQuestProgress = 0;

    if (lvl <= 0) {
      activeSkillQuestId = 'unlock_skill';
      activeSkillQuestGoal = 3 + runGrade ~/ 2 + currentFloor ~/ 3;
      activeSkillQuestIt =
          'Sblocca ${skill?.nameIt ?? target}: completa $activeSkillQuestGoal progressi Skill.';
      activeSkillQuestEn =
          'Unlock ${skill?.nameEn ?? target}: complete $activeSkillQuestGoal Skill progress.';
    } else {
      activeSkillQuestId = 'upgrade_skill';
      activeSkillQuestGoal = 4 + lvl + runGrade ~/ 2 + currentFloor ~/ 3;
      activeSkillQuestIt =
          'Potenzia ${skill?.nameIt ?? target}: completa $activeSkillQuestGoal progressi Skill.';
      activeSkillQuestEn =
          'Upgrade ${skill?.nameEn ?? target}: complete $activeSkillQuestGoal Skill progress.';
    }
  }

  void completeSkillQuest() {
    final id = activeSkillQuestTargetSkillId;
    final progress = artSkillProgress.putIfAbsent(
      id,
      () => _ArtSkillProgress(skillId: id),
    );
    final old = progress.level;
    if (old <= 0) {
      progress.level = 1;
    } else if (old < artSkillMaxLevel(id)) {
      progress.level++;
    }

    applyArtSkillPassive(id);
    final skill = findArtSkillDef(id);

    textIt =
        'Quest Skill Oculum completata!\n\n'
        '${skill?.nameIt ?? id}\n'
        'Prima: ${old <= 0 ? 'Bloccata' : 'Livello $old'}\n'
        'Ora: ${skillLevelLabel(id)}';
    textEn =
        'Oculum Skill Quest completed!\n\n'
        '${skill?.nameEn ?? id}\n'
        'Before: ${old <= 0 ? 'Locked' : 'Level $old'}\n'
        'Now: ${skillLevelLabel(id)}';

    addLog(
      t(
        'Quest Skill Oculum completata: ${skill?.nameIt ?? id}.',
        'Oculum Skill Quest completed: ${skill?.nameEn ?? id}.',
      ),
    );
    generateNextSkillQuest();
  }

  void applyArtSkillPassive(String skillId) {
    final skill = findArtSkillDef(skillId);
    if (skill == null) return;
    final lvl = skillLevel(skillId);
    if (lvl <= 0) return;
    final power = max(1, min(artSkillMaxLevel(skillId), lvl)).toInt();

    switch (skill.kind) {
      case 'damage':
        runDamageBonus += 1 + power;
        break;
      case 'defense':
        runDefenseBonus += 1 + power ~/ 2;
        gainPlayerShield(5 * power);
        elementalResist[activeElementId] =
            (elementalResist[activeElementId] ?? 0) + 1;
        break;
      case 'heal':
        addMaxHp(3 * power);
        if (power >= 3) runHealOnExplore += 1;
        break;
      case 'control':
        runCritBonus += 2 * power;
        nextEnemyWeakened = true;
        break;
      case 'utility':
        dungeonOculum += 1;
        if (power >= 2) gainOculumCharges(1);
        break;
      case 'special':
        runDamageBonus += power;
        runCritBonus += 3 * power;
        if (power >= 3) gainOculumCharges(1);
        break;
    }
  }

  void showStartRunWarning() {
    setState(() {
      clearChoices();

      textIt =
          'Avvertimento prima della run.\n\n'
          'Premendo Inizia davvero partirà una nuova run e verranno resettati solo i valori temporanei della run: HP run, Scudo run, nemici, drop nello zaino della run, quest attiva e bonus temporanei.\n\n'
          'NON verranno resettati: Oculum Spento, Art sbloccate, armi sbloccate, achievement e NPC buoni.\n\n'
          'La run resta salvabile tramite i progressi permanenti finché non perdi o la termini.';
      textEn =
          'Warning before the run.\n\n'
          'Pressing Truly Start will begin a new run and reset only temporary run values: run HP, run Shield, enemies, run drops, active quest and temporary bonuses.\n\n'
          'It will NOT reset: Spent Oculum, unlocked Arts, unlocked weapons, achievements and good NPCs.\n\n'
          'The run remains protected by permanent progress until you lose or end it.';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Inizia davvero',
          labelEn: 'Truly Start',
          icon: Icons.play_arrow,
          color: widget.tertiaryColor,
          onPressed: showDifficultyChoices,
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Annulla',
          labelEn: 'Cancel',
          icon: Icons.close,
          color: Colors.blueGrey,
          onPressed: () {
            setState(() {
              clearChoices();
              textIt = 'Run annullata. La palpebra resta chiusa.';
              textEn = 'Run cancelled. The eyelid stays closed.';
            });
          },
        ),
      );
    });
  }

  void showDifficultyChoices() {
    setState(() {
      clearChoices(mode: 'event');

      final noviceUnlocked = hasNoviceAchievement;

      textIt =
          'Scegli difficoltà.\n\n'
          'La prima prova Novizio permette solo Molto Facile, Facile e Normale.\n'
          'Difficile, Molto Difficile e Oculum si aprono dopo il primo completamento della prova, vinta o persa.';
      textEn =
          'Choose difficulty.\n\n'
          'The first Novice trial allows only Very Easy, Easy and Normal.\n'
          'Hard, Very Hard and Oculum open after the first trial completion, win or lose.';

      for (final option in _difficultyOptions) {
        final unlocked =
            option.unlockedByDefault || noviceUnlocked || firstRunGateSkipped;
        eventChoices.add(
          _DungeonChoice(
            labelIt: unlocked ? option.nameIt : 'Bloccata: ${option.nameIt}',
            labelEn: unlocked ? option.nameEn : 'Locked: ${option.nameEn}',
            icon: unlocked ? Icons.speed : Icons.lock,
            color: unlocked ? widget.tertiaryColor : Colors.grey,
            onPressed: unlocked
                ? () => chooseDifficulty(option)
                : () {
                    setState(() {
                      textIt =
                          '${option.nameIt} è bloccata finché non completi la prova Novizio.';
                      textEn =
                          '${option.nameEn} is locked until you complete the Novice trial.';
                    });
                  },
          ),
        );
      }

      if (!noviceUnlocked) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Salta prova Novizio',
            labelEn: 'Skip Novice trial',
            icon: Icons.skip_next,
            color: Colors.blueGrey,
            onPressed: () {
              setState(() {
                firstRunGateSkipped = true;
                completeAchievement('novice_gate');
                unlockNoviceRewards();
                showDifficultyChoices();
              });
            },
          ),
        );
      }
    });
  }

  void chooseDifficulty(_DifficultyOption option) {
    selectedDifficultyId = option.id;
    selectedDifficultyMultiplier = option.multiplier;
    tutorialRunActive = !hasNoviceAchievement && !firstRunGateSkipped;
    startRun();
  }

  void startRun() {
    setState(() {
      runCount++;
      clearRunCheckpoint();
      _savePermanentProgress();
      threat = calcThreat();
      runGrade = ((1 + threat ~/ 12).clamp(1, 5)).toInt();
      cycleDay = _random.nextInt(369) + 1;
      floorZeroCompleted = false;
      maxRooms = totalPlannedRooms;

      runActive = false;
      inCombat = false;
      gameOver = false;
      victory = false;

      room = 0;
      dungeonFloor = 1;
      playerMaxHp = max(30, widget.playerMaxHp);
      playerHp = playerMaxHp;
      playerShield = 0;
      playerOculumShield = 0;
      playerOculumShieldMax = 0;
      dungeonKarma = 0;

      dungeonLevel = 0;
      dungeonExp = 0;
      dungeonResilienza = 0;
      dungeonVolonta = 0;
      dungeonMateria = 0;
      dungeonOculum = 0;
      spentRunResilienza = 0;
      spentRunVolonta = 0;
      spentRunMateria = 0;
      spentRunOculum = 0;

      starterWeapon = null;
      activeCostume = null;
      activeArt = null;
      selectedRunArtIds.clear();
      oculianAllianceActive = false;
      gufusUsedThisRun = false;
      posteaGufusEventActive = false;
      posteaGufusEventPhase = '';
      posteaScientistTurnCounter = 0;
      posteaScientistEnhanced = false;
      monsterVillageFightActive = false;
      unlockedArtIds.remove('thousand_fires_emblem_art');
      final lowerPlayerName = widget.playerName.trim().toLowerCase();
      if (lowerPlayerName == 'kingi' || lowerPlayerName == 'ki korangi') {
        unlockedArtIds.add('defiled_postea_art');
      }
      activeRelic = null;
      activeCharacterOrigin = null;
      unlockedTitleIds.add('principiante');
      equippedTitleIds
        ..clear()
        ..add('principiante');
      titleLevels.putIfAbsent('principiante', () => 1);
      lastPrincipianteEvolutionLevel = titleLevel('principiante');
      randomTitleFloorRewardsClaimed.clear();
      titleChoiceRoomsClaimed.clear();
      gradeEventsSeenThisRun.clear();

      enemyHp = 0;
      enemyMaxHp = 0;
      enemyAttack = 0;
      enemyDefense = 0;
      enemyBleed = 0;
      enemyBurn = 0;
      enemyWeak = 0;
      enemyIsBoss = false;
      enemyIsElite = false;
      enemyNameIt = '';
      enemyNameEn = '';
      enemyElementId = 'neutral';

      // Prime run più guidate; dopo la terza si parte meglio.
      obserInRun = runCount > 3 ? 20 : 8;
      ascensionDustInRun = runCount > 3 ? 5 : 0;
      soulShards = 0;
      keys = 0;
      posteaRunicMetalKg = 0;

      runDamageBonus = 0;
      runDefenseBonus = 0;
      runCritBonus = 0;
      runLifesteal = 0;
      runHealOnExplore = 0;
      thornWhipRollBonus = 0;
      dodgeCharges = 0;
      skellyGuardCharges = 0;
      cipoSerpentHp = 0;
      cipoSerpentMaxHp = 0;
      posteaEliteGuardHp = 0;
      posteaEliteGuardMaxHp = 0;
      posteaEliteGuardShield = 0;
      posteaEliteGuardCriticalShieldActive = false;
      floralGuardCharges = 0;
      egoShieldHp = 0;
      egoWeaponStacks = 0;
      egoDefenseStacks = 0;
      relicNextRollBonus = 0;
      tribalDanceBuffFloor = 0;
      egoShieldBuffFloor = 0;
      oculumMaxCharges = oculianCostume ? 2 : 1;
      oculumCharges = oculumMaxCharges;

      combo = 0;
      killStreak = 0;
      roomsWithoutDamage = 0;
      fightsSinceTavernRest = 0;
      consecutivePlayerCritsThisFight = 0;

      reactionAvailable = true;
      secondChanceUsed = false;
      moonSecondChance = false;
      mapRevealed = false;
      nextRoomSafe = false;
      nextEnemyWeakened = false;
      levelUpRestAvailable = false;
      rebirthBlessingActive = false;
      rareLevelUpBlessingActive = false;

      merchantActionUsedThisRoom = false;
      merchantGearsSoldThisRoom = false;
      blacksmithActionUsedThisRoom = false;
      dropActionUsedThisRoom = false;
      restActionUsedThisRoom = false;
      levelUpRestAvailable = false;
      tavernMealUsedThisRoom = false;
      tavernMerchantActionUsedThisRoom = false;
      tavernBlacksmithActionUsedThisRoom = false;
      tavernSleepUsedThisRoom = false;
      monsterVillageFightActive = false;
      endRunOculumPaid = false;
      // NON resettare Oculum Spento: è una valuta permanente salvata.
      // oculumSpento resta quello caricato da SharedPreferences.

      freeReforges = 1;
      reforgeCount = 0;
      blacksmithFavor = 0;
      attachedDamageBonus = 0;
      attachedDefenseBonus = 0;
      attachedDrops.clear();
      inventoryDrops.clear();
      enemyParty.clear();
      defeatedEnemyNamesIt.clear();
      defeatedEnemyNamesEn.clear();
      activeAllies
        ..clear()
        ..addAll(
          _goodNpcs.where(
            (npc) =>
                selectedAllyIds.contains(npc.id) &&
                !(valleySacrificedInPostea &&
                    npc.id == 'valley_child_of_mother_nature'),
          ),
        );
      gufusUsedThisRun = activeAllies.any((npc) => npc.id == 'gufus_leviante');
      for (final npc in activeAllies.where(isSmallNpc)) {
        prepareSmallNpcActions(npc, forceRefresh: true);
      }
      if (posteaEliteGuardInParty) {
        activatePosteaEliteGuard(refill: true);
      }
      // Solo questi alleati entrano dalla selezione pre-run; gli altri devono essere trovati nella run.
      multiEnemyBattlesWon = 0;
      aoeCasts = 0;
      oculumSkillCasts = 0;
      merchantBuys = 0;
      eliteVaultsCleared = 0;
      occultScrollsFound = 0;
      elementalComboHits = 0;
      artTechniqueCooldown = 0;
      artTechniqueUses = 0;
      drownedSummonTurns = 0;
      evonestProof = 0;
      asherContractUses = 0;
      asherWatched = false;
      woundedAllyAssistReady = false;
      criticalShieldActive = false;
      criticalShieldBlocks = 0;
      potionsUsed = 0;
      dropsStudied = 0;
      enemyDropsConverted = 0;
      fifiSleepActions = 0;
      vervainBuffFloor = 0;
      skeletonHandsHp = 0;
      skeletonHandsMaxHp = 0;
      pawnHp = 0;
      pawnMaxHp = 0;
      pawnShield = 0;
      oculianKills = 0;
      relicOpenLastFloor.clear();
      minorOculianSeen = false;
      thousandEyesChildSeen = false;
      titleEventUsedThisFloor = false;
      positiveTitleEventsSeen = 0;
      blindSpotTitleEventsSeen = 0;
      baghestCultistCostume = false;
      oculianCostume = false;
      potionMinor = 1;
      potionMajor = 0;
      potionShield = 0;
      potionOculum = 0;
      potionCleanse = 0;
      potionSmoke = 0;
      enemyDropHistoryIt.clear();
      enemyDropHistoryEn.clear();

      for (final e in _elements) {
        elementalResist[e.id] = 0;
      }

      activeQuestIt = '';
      activeQuestEn = '';
      activeQuestId = '';
      activeQuestProgress = 0;
      activeQuestGoal = 0;
      questCompleted = false;

      activeSkillQuestIt = '';
      activeSkillQuestEn = '';
      activeSkillQuestId = '';
      activeSkillQuestTargetSkillId = '';
      activeSkillQuestProgress = 0;
      activeSkillQuestGoal = 0;

      purchasedRelics.clear();
      runBoons.clear();
      weakNpcRunEncounteredIds.clear();
      earlyDustRoomsClaimed.clear();
      clearChoices();
      log.clear();

      generateQuest();
      applyCalendarStartEffect();

      textIt =
          'Run $runCount preparata.\n\n'
          '${cyclePhaseLine()}\n'
          'Scegli il personaggio iniziale: ogni scelta ha un piccolo buff e può aprire eventi diversi.\n'
          'Poi sceglierai reliquia, arma, armatura, Art e prima Skill Oculum.\n\n'
          'Oculus = occhio magico.\n'
          'Oculum = potere magico.\n\n'
          '12 piani • $roomsPerFloor stanze per piano • boss a fine piano.\n'
          'Il dungeon legge la scheda: HP, VC, CM, danno, difesa, livello e grado impostano i fight.\n'
          'La difficoltà cresce proceduralmente se la run sta andando bene.\n'
          '${runCount > 3 ? 'Bonus post-terza run: 20 Obser e 5 Ascension Dust.\n' : 'Prime 3 run: partenza fragile, shop più semplice.\n'}'
          'Primo reforge del fabbro: gratis.\n'
          'Oculum Spento permanente: $oculumSpento.';

      textEn =
          'Run $runCount prepared.\n\n'
          '${cyclePhaseLine()}\n'
          'Choose the starting character: every choice has a small buff and can open different events.\n'
          'Then you will choose relic, weapon, armor, Art and first Oculum Skill.\n\n'
          'Oculus = magical eye.\n'
          'Oculum = magical power.\n\n'
          '12 floors • $roomsPerFloor rooms per floor • boss at each floor end.\n'
          'The dungeon reads your sheet: HP, VC, CM, damage, defense, level and grade set the fights.\n'
          'Difficulty grows procedurally when the run goes well.\n'
          '${runCount > 3 ? 'Post-third-run bonus: 20 Obser and 5 Ascension Dust.\n' : 'First 3 runs: fragile start, simpler shop.\n'}'
          'First blacksmith reforge: free.\n'
          'Permanent Spent Oculum: $oculumSpento.';

      for (final origin in _characterOrigins) {
        final unlocked = isCharacterOriginUnlocked(origin);
        eventChoices.add(
          _DungeonChoice(
            labelIt: unlocked ? origin.nameIt : 'Bloccata: ${origin.nameIt}',
            labelEn: unlocked ? origin.nameEn : 'Locked: ${origin.nameEn}',
            icon: unlocked ? Icons.person : Icons.lock,
            color: unlocked ? origin.primaryColor : Colors.grey,
            onPressed: unlocked
                ? () => chooseCharacterOrigin(origin)
                : () {
                    setState(() {
                      textIt =
                          '${origin.nameIt} e bloccato.\nSblocca il relativo achievement o la reliquia collegata.';
                      textEn =
                          '${origin.nameEn} is locked.\nUnlock the related achievement or linked relic.';
                    });
                  },
          ),
        );
      }

      addLog(t('Run preparata.', 'Run prepared.'));
    });
  }

  void applyCharacterOriginBonus(_CharacterOrigin origin) {
    activeCharacterOrigin = origin;
    if (origin.hpBonus > 0) addMaxHp(origin.hpBonus);
    gainPlayerShield(origin.shieldBonus);
    runDamageBonus += origin.damageBonus;
    runDefenseBonus += origin.defenseBonus;
    dungeonOculum += origin.oculumBonus;
    if (origin.oculumBonus > 0) {
      oculumMaxCharges += origin.oculumBonus;
      oculumCharges = max(oculumCharges, oculumMaxCharges).toInt();
    }
    final isPawn = origin.id == 'pawn_awakened';
    final isOculianCultist =
        origin.id == 'male_oculian_cultist' ||
        origin.id == 'female_oculian_cultist';
    oculianAllianceActive = isOculianCultist;
    if (isOculianCultist) {
      final minor = npcById('minor_oculian_watcher');
      if (minor != null) {
        unlockedNpcIds.add(minor.id);
        addAllyToParty(minor, replaceIfFull: true, save: false);
      }
      textIt +=
          '\n\nPatto Oculiano attivo: gli Oculiani non ti cacciano e possono aiutarti.';
      textEn +=
          '\n\nOculian pact active: Oculians no longer hunt you and may assist you.';
    }
    selectedSkinId = isPawn ? 'pawn' : 'base_oculum';
  }

  bool isCharacterOriginUnlocked(_CharacterOrigin origin) {
    if (origin.id == 'pawn_awakened') {
      return completedAchievementIds.contains('pawn_relic_unlocked') ||
          unlockedRelicIds.contains('pawn_guardiano');
    }
    if (origin.id == 'neutral_relic_witness') {
      return completedAchievementIds.contains('floor_three_title') ||
          unlockedRelicIds.contains('nido_di_muschio') ||
          unlockedRelicIds.contains('occhio_della_reliquia');
    }
    if (origin.id == 'male_oculian_cultist' ||
        origin.id == 'female_oculian_cultist') {
      return completedAchievementIds.contains('oculian_costume_unlocked') ||
          completedAchievementIds.contains('three_oculians') ||
          unlockedCostumeIds.contains('oculian_eye_mantle');
    }
    return true;
  }

  void chooseCharacterOrigin(_CharacterOrigin origin) {
    setState(() {
      applyCharacterOriginBonus(origin);
      clearChoices();

      textIt =
          'Personaggio scelto:\n${origin.nameIt}\n\n'
          '${origin.descIt}\n\n'
          'Ora scegli la reliquia iniziale.';
      textEn =
          'Character chosen:\n${origin.nameEn}\n\n'
          '${origin.descEn}\n\n'
          'Now choose the starting relic.';

      for (final relic in randomStartingRelicChoices()) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: relic.nameIt,
            labelEn: relic.nameEn,
            icon: Icons.auto_awesome,
            color: widget.tertiaryColor,
            onPressed: () => chooseStartingRelic(relic),
          ),
        );
      }
    });
  }

  void chooseStartingRelic(_RelicDef relic) {
    setState(() {
      activeRelic = relic;
      applyRelicStartBonus(relic);
      clearChoices();

      textIt =
          'Reliquia scelta:\n${relic.nameIt}\n\n'
          '${relic.descIt}\n\n'
          'Ora scegli una delle 3 armi iniziali.';
      textEn =
          'Relic chosen:\n${relic.nameEn}\n\n'
          '${relic.descEn}\n\n'
          'Now choose one of 3 starting weapons.';

      for (final weapon in randomStartingWeaponChoices()) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: weapon.nameIt,
            labelEn: weapon.nameEn,
            icon: Icons.gps_fixed,
            color: elementColor(weapon.elementId),
            onPressed: () => chooseStarterWeapon(weapon),
          ),
        );
      }
    });
  }

  void applyRelicStartBonus(_RelicDef relic) {
    purchasedRelics.add(relic.effectId);

    switch (relic.effectId) {
      case 'ahrya_extra_ally':
        break;
      case 'skeleton_hands':
        skeletonHandsMaxHp = playerMaxHp;
        skeletonHandsHp = skeletonHandsMaxHp;
        activeAllies.removeWhere((npc) => npc.id == 'giant_skull_tavernkeeper');
        break;
      case 'pawn_guardian':
        pawnMaxHp = 120;
        pawnHp = pawnMaxHp;
        pawnShield = 10;
        break;
      case 'rebirth_seed':
        rebirthBlessingActive = true;
        break;
      case 'baghest_eye':
        baghestEyeOwned = true;
        break;
      case 'baghest_cultist_costume':
        baghestCultistCostume = true;
        break;
      case 'oculian_costume':
        oculianCostume = true;
        oculumMaxCharges = 2;
        oculumCharges = max(oculumCharges, oculumMaxCharges);
        break;
      case 'oculum_shield_converter':
        {
          final convertedShield = playerShield;
          final oldMaxHp = playerMaxHp;
          playerShield = 0;
          playerMaxHp = max(1, (playerMaxHp * 0.40).ceil()).toInt();
          playerHp = min(playerHp, playerMaxHp);
          gainOculumShield(50 + convertedShield, expandMaximum: true);
          runBoons.add('oculum_shield_converter');
          addLog(
            t(
              'Occhio dello Scudo Oculum: HP massimi $oldMaxHp -> $playerMaxHp, Scudo Oculum $playerOculumShield/$playerOculumShieldMax.',
              'Oculum Shield Eye: max HP $oldMaxHp -> $playerMaxHp, Oculum Shield $playerOculumShield/$playerOculumShieldMax.',
            ),
          );
          break;
        }
      case 'cold_feather':
        dodgeCharges += 2;
        runCritBonus += 4;
        break;
      case 'ancient_obser':
        obserInRun += 12;
        break;

      case 'starter_leaf_pin':
        runBoons.add('starter_leaf_pin');
        break;

      case 'starter_kooba_gear':
        obserInRun += 3;
        runBoons.add('starter_kooba_gear');
        break;

      case 'starter_tiny_vitalium':
        addMaxHp(10);
        addQuickPotion('minor', amount: 1);
        break;
      default:
        final effect = relic.effectId;
        if (effect.startsWith('minor_')) {
          final element = effect.replaceFirst('minor_', '');
          elementalResist[element] = (elementalResist[element] ?? 0) + 1;
          runDamageBonus += 1;
        }
    }
  }

  List<_RunCostume> availableStartingCostumes() {
    return _runCostumes
        .where(
          (c) =>
              (c.unlockedByDefault || unlockedCostumeIds.contains(c.id)) &&
              (!isPosteaCostumeId(c.id) || posteaGufusEventCompleted),
        )
        .toList();
  }

  List<_RunCostume> randomStartingCostumeChoices() {
    final costumes = List<_RunCostume>.from(availableStartingCostumes())
      ..shuffle(_random);
    return costumes.take(3).toList();
  }

  void applyStartingCostume(_RunCostume costume) {
    activeCostume = costume;
    addMaxHp(costume.hpBonus);
    gainPlayerShield(costume.shieldBonus);
    runDefenseBonus += costume.defenseBonus;
    runDamageBonus += costume.damageBonus;
    runCritBonus += costume.critBonus;
    dungeonOculum += costume.oculumBonus;

    if (costume.id == 'starlit_vagrant_coat') {
      dodgeCharges += 1;
    }

    if (costume.id == 'moss_choir_garb') {
      runHealOnExplore += 1;
    }

    if (costume.id == 'vitalium_rebirth_gown') {
      runHealOnExplore += 1;
    }

    if (costume.id == 'evonest_triple_shell') {
      elementalResist['water'] = (elementalResist['water'] ?? 0) + 2;
      elementalResist['poison'] = (elementalResist['poison'] ?? 0) + 1;
    }

    if (costume.id == 'asher_burnt_contract') {
      runBoons.add('asher_physical_burn');
    }

    if (costume.id == 'drowned_city_robe') {
      drownedSummonTurns = max(drownedSummonTurns, 3).toInt();
    }

    if (costume.id == 'hidenas_thousand_ember_uniform') {
      elementalResist['fire'] = (elementalResist['fire'] ?? 0) + 2;
    }

    if (costume.id == 'vapium_vapor_plate') {
      dungeonMateria += 1;
    }

    if (costume.id == 'postea_elite_armor') {
      criticalShieldActive = true;
      criticalShieldBlocks = 0;
    }

    if (costume.id == 'moonhills_lunium_veil') {
      dodgeCharges += 1;
    }

    if (costume.id == 'obser_merchant_jacket') {
      obserInRun += 18;
    }

    if (costume.id == 'baghest_cultist_armor') {
      baghestCultistCostume = true;
    }

    if (costume.id == 'oculian_eye_mantle') {
      oculianCostume = true;
      oculumMaxCharges = max(oculumMaxCharges, 2).toInt();
      oculumCharges = max(oculumCharges, oculumMaxCharges).toInt();
    }
  }

  void chooseStartingCostume(_RunCostume costume) {
    setState(() {
      applyStartingCostume(costume);
      clearChoices();

      textIt =
          'Hai indossato: ${costume.nameIt}\n\n'
          '${costume.descIt}\n\n'
          'Ora scegli la tua Art iniziale.';
      textEn =
          'You wear: ${costume.nameEn}\n\n'
          '${costume.descEn}\n\n'
          'Now choose your starting Art.';

      final arts = List<_DungeonArt>.from(availableStartingArts())
        ..shuffle(_random);
      for (final art in arts.take(6)) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: art.nameIt,
            labelEn: art.nameEn,
            icon: Icons.auto_fix_high,
            color: elementColor(art.elementId),
            onPressed: () => chooseStartingArt(art),
          ),
        );
      }
    });
  }

  void chooseStarterWeapon(_StarterWeapon weapon) {
    setState(() {
      starterWeapon = weapon;
      gainPlayerShield(weapon.shieldBonus);
      dungeonOculum += weapon.oculumBonus;
      oculumMaxCharges += weapon.oculumCharges;
      oculumCharges = min(
        oculumMaxCharges,
        oculumCharges + weapon.oculumCharges,
      );

      if (weapon.id.contains('mimic')) dodgeCharges += 1;
      if (weapon.id.contains('blood')) runLifesteal += 1;
      if (weapon.id == 'postea_auto_rifle') runCritBonus += 3;
      if (weapon.id == 'postea_grenades') runBoons.add('postea_free_vc_aoe');
      if (weapon.id == 'combattimento_mani_nude') {
        runCritBonus += 2;
        runBoons.add('bare_hand_combat');
        unlockedArtIds.add('swiftness_martial_art');
      }

      clearChoices();

      textIt =
          'Hai scelto: ${weapon.nameIt}\n\n'
          '${weapon.descIt}\n\n'
          'Ora scegli armatura/costume iniziale: 1 fra 3 sbloccati.';
      textEn =
          'You chose: ${weapon.nameEn}\n\n'
          '${weapon.descEn}\n\n'
          'Now choose starting armor/costume: 1 among 3 unlocked.';

      final costumes = randomStartingCostumeChoices();
      for (final costume in costumes) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: costume.nameIt,
            labelEn: costume.nameEn,
            icon: Icons.checkroom,
            color: elementColor(costume.elementId),
            onPressed: () => chooseStartingCostume(costume),
          ),
        );
      }
    });
  }

  void chooseStartingArt(_DungeonArt art) {
    setState(() {
      runActive = false;
      clearChoices();

      if (hasOculianPact) {
        selectedRunArtIds.add(art.effectId);
        activeArt = art;
        final chosen = selectedRunArtIds.length;
        if (chosen < 3) {
          textIt =
              'Art scelta: ${art.nameIt}\n\n'
              'Patto Oculiano attivo: scegli ${3 - chosen} Art aggiuntive (totale 3).';
          textEn =
              'Art chosen: ${art.nameEn}\n\n'
              'Oculian pact active: pick ${3 - chosen} more Arts (total 3).';
          final arts = List<_DungeonArt>.from(availableStartingArts())
            ..removeWhere((a) => selectedRunArtIds.contains(a.effectId))
            ..shuffle(_random);
          for (final option in arts.take(6)) {
            eventChoices.add(
              _DungeonChoice(
                labelIt: option.nameIt,
                labelEn: option.nameEn,
                icon: Icons.auto_fix_high,
                color: elementColor(option.elementId),
                onPressed: () => chooseStartingArt(option),
              ),
            );
          }
          return;
        }
      }

      activeArt = art;
      selectedRunArtIds.add(art.effectId);
      applyStartingArtBonus(art);

      final ids = ensureThreeRandomSkillsForArt(art);

      textIt =
          'Hai scelto:\n${art.nameIt}\n\n'
          '${art.descIt}\n\n'
          'Il dungeon prepara 3 Skill Oculum uniche per questa Art.\n'
          'Scegli quale sbloccare per prima.';
      textEn =
          'You chose:\n${art.nameEn}\n\n'
          '${art.descEn}\n\n'
          'The dungeon prepares 3 unique Oculum Skills for this Art.\n'
          'Choose which one to unlock first.';

      for (final id in ids) {
        final skill = findArtSkillDef(id);
        if (skill == null) continue;
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Sblocca: ${skill.nameIt}',
            labelEn: 'Unlock: ${skill.nameEn}',
            icon: Icons.visibility,
            color: elementColor(art.elementId),
            onPressed: () => chooseFirstArtSkill(id),
          ),
        );
      }
    });
  }

  void chooseFirstArtSkill(String skillId) {
    setState(() {
      clearChoices();
      final progress = artSkillProgress.putIfAbsent(
        skillId,
        () => _ArtSkillProgress(skillId: skillId),
      );
      progress.level = max(progress.level, 1).toInt();

      applyArtSkillPassive(skillId);
      applyEquippedTitleStartBonuses();
      generateNextSkillQuest();
      runActive = true;
      valleyEncounterSeenThisRun = false;
      valleyTrainingUsedThisRun = false;
      valleyTrainingActive = false;
      valleyTrainingRewardClaimed = false;
      valleyParticipatedInFight = false;
      valleyBloomResolvedThisFight = false;
      valleyTurnsLeft = 0;
      valleyHp = 0;
      valleyMaxHp = 0;
      valleyAttack = 0;
      valleyDefense = 0;
      valleyBloomGuards = 0;
      valleyTrainingTurnsLeft = 0;
      saveRunCheckpoint(
        reasonIt: 'Run iniziata: primo ricordo inciso.',
        reasonEn: 'Run started: first memory engraved.',
      );

      final skill = findArtSkillDef(skillId);
      textIt =
          'Prima Skill Oculum sbloccata:\n${skill?.nameIt ?? skillId}\n\n'
          'La run comincia davvero con Principiante attivo.\n'
          'Ogni 2 stanze il dungeon ti offrirà 3 Titoli casuali e ne sceglierai 1.\n\n'
          'Missione:\n$activeQuestIt\n\n'
          'Quest Skill:\n$activeSkillQuestIt';
      textEn =
          'First Oculum Skill unlocked:\n${skill?.nameEn ?? skillId}\n\n'
          'The run truly begins with Beginner active.\n'
          'Every 2 rooms the dungeon will offer 3 random Titles and you will choose 1.\n\n'
          'Quest:\n$activeQuestEn\n\n'
          'Skill Quest:\n$activeSkillQuestEn';
    });
  }

  void applyEquippedTitleStartBonuses() {
    if (equippedTitleIds.contains('principiante')) {
      addMaxHp(30);
      gainPlayerShield(20);
      runDamageBonus += 2;
    }

    for (final title in equippedTitles.where(
      (title) => title.id != 'principiante',
    )) {
      applySingleTitleRunBonus(title);
    }
  }

  void applyStartingArtBonus(_DungeonArt art) {
    switch (art.elementId) {
      case 'fire':
        runDamageBonus += 2;
        break;
      case 'water':
        addMaxHp(8);
        runHealOnExplore += 1;
        break;
      case 'wind':
        dodgeCharges += 1;
        runCritBonus += 3;
        break;
      case 'earth':
        runDefenseBonus += 2;
        gainPlayerShield(25);
        break;
      case 'lightning':
        runDamageBonus += 3;
        break;
      case 'ice':
        runDefenseBonus += 1;
        nextEnemyWeakened = true;
        break;
      case 'sound':
        runCritBonus += 8;
        break;
      case 'poison':
        runDamageBonus += 1;
        break;
      case 'blood':
        runLifesteal += 1;
        break;
      case 'shadow':
        runLifesteal += 1;
        dungeonOculum += 1;
        break;
      case 'moon':
        addMaxHp(10);
        dungeonOculum += 1;
        break;
      case 'sun':
        runCritBonus += 8;
        runDamageBonus += 1;
        break;
      case 'vapium':
        runDefenseBonus += 2;
        gainPlayerShield(20);
        break;
      default:
        runDamageBonus += 2;
    }
  }

  void generateQuest() {
    final quests = [
      [
        'kills',
        5 + runGrade,
        'Sconfiggi ${5 + runGrade} nemici.',
        'Defeat ${5 + runGrade} enemies.',
      ],
      ['elite', 2, 'Sconfiggi 2 élite corrotte.', 'Defeat 2 corrupted elites.'],
      ['treasure', 3, 'Trova 3 tesori.', 'Find 3 treasures.'],
      [
        'no_damage',
        3,
        'Completa 3 stanze senza subire danno.',
        'Complete 3 rooms without taking damage.',
      ],
      ['oculum', 2, 'Usa 2 Skill Oculum.', 'Use 2 Oculum Skills.'],
      ['art', 1, 'Trova o sblocca una nuova Art.', 'Find or unlock a new Art.'],
      ['drop', 1, 'Ottieni un drop unico.', 'Obtain a unique drop.'],
    ];

    final q = quests[_random.nextInt(quests.length)];
    activeQuestId = q[0] as String;
    activeQuestGoal = q[1] as int;
    activeQuestIt = q[2] as String;
    activeQuestEn = q[3] as String;
  }

  void applyCalendarStartEffect() {
    switch (cyclePhase().id) {
      case 'safe_monster':
        runDefenseBonus += 1;
        addLog(
          t(
            'Safe Monster: nemici meno aggressivi.',
            'Safe Monster: enemies are less aggressive.',
          ),
        );
        break;
      case 'illness':
        threat += 2;
        runCritBonus += 1;
        addLog(
          t(
            'Illness: trappole e follia più presenti.',
            'Illness: traps and madness are more present.',
          ),
        );
        break;
      case 'little_breath':
        unlockRandomTitle();
        addLog(
          t(
            'Little Breath: il Fato lascia un Titolo.',
            'Little Breath: Fate leaves a Title.',
          ),
        );
        break;
      case 'fertile_rain':
        potionCleanse += 1;
        addLog(
          t(
            'Piogge Fertilizzanti: +1 pozione pulizia.',
            'Fertilizing Rains: +1 cleanse potion.',
          ),
        );
        break;
      case 'sun':
        runDamageBonus += 2;
        playerShield = max(0, playerShield - 4);
        addLog(
          t(
            'The Sun: +2 danno, scudo iniziale secco.',
            'The Sun: +2 damage, dry starting shield.',
          ),
        );
        break;
      case 'moon':
        oculumMaxCharges += 1;
        oculumCharges = oculumMaxCharges;
        addLog(t('The Moon: +1 Oculum massimo.', 'The Moon: +1 max Oculum.'));
        break;
      case 'fate':
        runCritBonus += 4;
        addLog(t('The Fate: +4 critico.', 'The Fate: +4 critical.'));
        break;
      case 'heat':
        playerMaxHp = max(1, playerMaxHp - 8);
        playerHp = min(playerHp, playerMaxHp);
        runDamageBonus += 1;
        addLog(
          t(
            'Caldo Infernale: meno HP, +1 danno.',
            'Infernal Heat: less HP, +1 damage.',
          ),
        );
        break;
      case 'null':
        oculumSpento += 1;
        addLog(t('The Null: +1 Oculum Spento.', 'The Null: +1 Spent Oculum.'));
        break;
      case 'ice':
        runDefenseBonus += 2;
        runDamageBonus = max(0, runDamageBonus - 1);
        addLog(
          t(
            'Ghiaccio Imponente: +2 difesa, attacco rallentato.',
            'Imposing Ice: +2 defense, slowed attack.',
          ),
        );
        break;
      default:
        break;
    }
  }

  void progressQuest(String id, {int amount = 1}) {
    if (questCompleted || activeQuestId != id) return;
    activeQuestProgress += amount;
    if (activeQuestProgress >= activeQuestGoal) {
      questCompleted = true;
      final rewardObser = 8 + runGrade + currentFloor;
      final rewardDust = 1 + runGrade ~/ 3 + currentFloor ~/ 4;
      obserInRun += rewardObser;
      ascensionDustInRun += rewardDust;
      widget.onReward(
        obser: rewardObser,
        ascensionDust: rewardDust,
        log: 'Dungeon quest: +$rewardObser Obser, +$rewardDust Dust.',
      );
      addLog(
        t(
          'Missione completata: +$rewardObser Obser, +$rewardDust Dust.',
          'Quest completed: +$rewardObser Obser, +$rewardDust Dust.',
        ),
      );
    }
  }

  void gainDungeonExp(int amount, {bool forceLevelCheck = true}) {
    dungeonExp += amount;
    addLog(
      t(
        '+$amount EXP dungeon. [$dungeonExp/$expToNextDungeonLevel]',
        '+$amount dungeon EXP. [$dungeonExp/$expToNextDungeonLevel]',
      ),
    );
    if (forceLevelCheck && dungeonExp >= expToNextDungeonLevel && !inCombat) {
      offerDungeonLevelUp(
        reasonIt: 'Hai accumulato abbastanza EXP.',
        reasonEn: 'You gained enough EXP.',
      );
    }
  }

  void offerDungeonLevelUp({
    required String reasonIt,
    required String reasonEn,
  }) {
    if (gameOver || inCombat) return;

    refreshDungeonUi(() {
      clearChoices();

      textIt =
          '$reasonIt\n\n'
          'Level up del dungeon disponibile.\n'
          'Scegli la statistica che riceve +3.';
      textEn =
          '$reasonEn\n\n'
          'Dungeon level up available.\n'
          'Choose the stat that receives +3.';

      for (final stat in ['res', 'vol', 'mat', 'ocu']) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: '+3 ${statLabel(stat)}',
            labelEn: '+3 ${statLabel(stat)}',
            icon: Icons.add_circle,
            color: widget.tertiaryColor,
            onPressed: () => chooseLevelThreeStat(stat),
          ),
        );
      }
    });
  }

  String statLabel(String stat) {
    switch (stat) {
      case 'res':
        return t('Resilienza', 'Resilience');
      case 'vol':
        return t('Volontà', 'Will');
      case 'mat':
        return 'Materia';
      case 'ocu':
        return 'Oculum';
      default:
        return stat;
    }
  }

  void chooseLevelThreeStat(String stat) {
    setState(() {
      clearChoices();
      textIt =
          'Hai scelto +3 a ${statLabel(stat)}.\nOra scegli una statistica diversa per il +2.';
      textEn =
          'You chose +3 to ${statLabel(stat)}.\nNow choose a different stat for +2.';

      for (final second in [
        'res',
        'vol',
        'mat',
        'ocu',
      ].where((s) => s != stat)) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: '+2 ${statLabel(second)}',
            labelEn: '+2 ${statLabel(second)}',
            icon: Icons.add,
            color: widget.primaryColor,
            onPressed: () => applyDungeonLevelUp(stat, second),
          ),
        );
      }
    });
  }

  void applyDungeonLevelUp(String plusThree, String plusTwo) {
    setState(() {
      clearChoices();
      final spentExp = expToNextDungeonLevel;
      dungeonExp = max(0, dungeonExp - spentExp);
      dungeonLevel++;

      for (final stat in ['res', 'vol', 'mat', 'ocu']) {
        int amount = 1;
        if (stat == plusThree) amount = 3;
        if (stat == plusTwo) amount = 2;

        switch (stat) {
          case 'res':
            dungeonResilienza += amount;
            addMaxHp(amount * 10);
            break;
          case 'vol':
            dungeonVolonta += amount;
            break;
          case 'mat':
            dungeonMateria += amount;
            break;
          case 'ocu':
            dungeonOculum += amount;
            oculumCharges += amount ~/ 2;
            break;
        }
      }

      final shieldGain = 10 + dungeonLevel * 5;
      gainPlayerShield(shieldGain);
      levelUpRestAvailable = true;

      final rareChance = dungeonLevel >= 3
          ? 1 + currentFloor ~/ 4 + (isInLastSixteenRooms ? 1 : 0)
          : 1;
      final rareBlessing = chance(rareChance);

      var rareIt = '';
      var rareEn = '';

      if (rareBlessing) {
        criticalShieldActive = true;
        criticalShieldBlocks = 0;
        rebirthBlessingActive = true;
        rareLevelUpBlessingActive = true;
        gainPlayerShield(25 + dungeonLevel * 3);

        rareIt =
            '\n\nEVENTO RARISSIMO DI LEVEL UP:\n'
            'Scudo Critico attivo.\n'
            'Rinascita attiva: se cadi a 0 HP, torni una volta al 35% HP.';
        rareEn =
            '\n\nRARE LEVEL UP EVENT:\n'
            'Critical Shield active.\n'
            'Rebirth active: if you fall to 0 HP, you return once at 35% HP.';
      }

      textIt =
          'Level up del dungeon!\n'
          '+3 ${statLabel(plusThree)}\n'
          '+2 ${statLabel(plusTwo)}\n'
          '+1 alle altre statistiche\n'
          '+$shieldGain Scudo.\n\n'
          'Ora puoi usare Riposo una volta per ricaricare almeno metà vita e metà Oculum.'
          '$rareIt';
      textEn =
          'Dungeon level up!\n'
          '+3 ${statLabel(plusThree)}\n'
          '+2 ${statLabel(plusTwo)}\n'
          '+1 to the other stats\n'
          '+$shieldGain Shield.\n\n'
          'You can now use Rest once to refill at least half HP and half Oculum.'
          '$rareEn';

      if (dungeonExp >= expToNextDungeonLevel) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Altro level up disponibile',
            labelEn: 'Another level up available',
            icon: Icons.upgrade,
            color: widget.tertiaryColor,
            onPressed: () => offerDungeonLevelUp(
              reasonIt: 'Hai ancora abbastanza EXP.',
              reasonEn: 'You still have enough EXP.',
            ),
          ),
        );
      }
    });

    _savePermanentProgress();
    saveRunCheckpoint(
      reasonIt: 'Level up dungeon salvato.',
      reasonEn: 'Dungeon level up saved.',
    );
  }

  double roomDifficultyFactor() {
    // Ancora procedurale, ma più respirabile:
    // i primi piani non ti schiacciano subito e la scheda forte pesa meno.
    final earlyRunMercy = runCount <= 3 ? 0.16 : 0.05;
    final floorCurve = 0.18 + currentFloor * 0.058;
    final roomCurve = (room / max(1, maxRooms)) * 0.38;
    final threatCurve = threat * 0.008;
    final calendarCurve =
        calendarDangerBonus('combat') * 0.045 -
        calendarEventBonus('rest') * 0.018;
    final sheetCurve = (sheetPowerScore / 690.0).clamp(0.0, 0.75);
    final successCurve = min(0.30, killStreak * 0.018 + dungeonLevel * 0.026);
    final raw =
        floorCurve +
        roomCurve +
        threatCurve +
        calendarCurve +
        sheetCurve +
        successCurve -
        earlyRunMercy;

    return raw.clamp(0.18, runCount <= 3 ? 1.35 : 1.90).toDouble();
  }

  bool get hasKoobaInParty =>
      activeAllies.any((npc) => npc.id == 'kooba_glimmer_moralist');

  void gainKoobaGearsForPeacefulRoom() {
    if (inCombat || gameOver) return;

    if (!hasKoobaInParty && !hasRunFlag('starter_kooba_gear')) return;

    final gained = hasKoobaInParty
        ? 1 + (chance(18) ? 1 : 0)
        : (chance(22) ? 1 : 0);
    if (gained <= 0) return;
    sparklingGears += gained;
    addLog(
      t(
        'Kooba raccoglie $gained ingranaggi scintillanti.',
        'Kooba gathers $gained glimmering gears.',
      ),
    );
  }

  void peacefulMonstersEvent() {
    clearChoices(mode: 'event');
    peacefulMonstersMet = true;
    completeAchievement('peaceful_monsters_kooba');

    textIt =
        'Mostri pacifici.\n\n'
        'Tra muffa dolce e pietruzze lucide trovi un Kooba: sembra un jerboa dalle orecchie lunghe, con un cranio leggero sulla testa.\n'
        'Non prende tutto. Sceglie solo piccoli oggetti scintillanti già abbandonati, come se avesse una morale troppo grande per il suo corpo.\n\n'
        'Intorno a lui rotolano piccoli kitty slime, morbidi e sospettosi.';
    textEn =
        'Peaceful monsters.\n\n'
        'Between sweet mold and shiny pebbles you find a Kooba: a jerboa-like creature with long ears and a light skull on its head.\n'
        'It does not take everything. It only chooses small abandoned glimmering objects, as if its moral code were too large for its body.\n\n'
        'Tiny kitty slimes roll around it, soft and suspicious.';

    if (!unlockedNpcIds.contains('kooba_glimmer_moralist')) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Invita Kooba nel party',
          labelEn: 'Invite Kooba to the party',
          icon: Icons.pets,
          color: const Color(0xFFFFD36A),
          onPressed: recruitKooba,
        ),
      );
    }

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Raccogli con rispetto',
        labelEn: 'Gather respectfully',
        icon: Icons.auto_awesome,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            final gained = 2 + _random.nextInt(3);
            sparklingGears += gained;
            clearChoices();
            textIt =
                'Raccogli solo ciò che brilla già lontano dai nidi.\n'
                'Kooba ti osserva e non si offende.\n\n'
                '+$gained Ingranaggi Scintillanti.';
            textEn =
                'You gather only what already shines far from the nests.\n'
                'Kooba watches you and does not take offense.\n\n'
                '+$gained Glimmering Gears.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Lascia dormire i kitty slime',
        labelEn: 'Let the kitty slimes sleep',
        icon: Icons.nightlight,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            nextRoomSafe = true;
            textIt =
                'Non tocchi nulla.\n'
                'I kitty slime fanno un verso minuscolo, quasi un grazie.\n'
                'La prossima stanza sembra meno aggressiva.';
            textEn =
                'You touch nothing.\n'
                'The kitty slimes make a tiny sound, almost a thank you.\n'
                'The next room feels less aggressive.';
          });
        },
      ),
    );
  }

  void recruitKooba() {
    setState(() {
      unlockedNpcIds.add('kooba_glimmer_moralist');
      final kooba = _goodNpcs.firstWhere(
        (npc) => npc.id == 'kooba_glimmer_moralist',
      );

      final joined = addAllyToParty(kooba, replaceIfFull: true);
      sparklingGears += 3;
      if (!joined) {
        unlockedNpcIds.add('kooba_glimmer_moralist');
        _savePermanentProgress();
      }
      checkPassiveAchievements();
      clearChoices();

      textIt =
          'Kooba si unisce al party.\n\n'
          'Non promette fedeltà. Promette di non rubare.\n'
          'Da ora, nelle stanze senza fight, può raccogliere Ingranaggi Scintillanti.\n\n'
          '+3 Ingranaggi Scintillanti.';
      textEn =
          'Kooba joins the party.\n\n'
          'It does not promise loyalty. It promises not to steal.\n'
          'From now on, in rooms without fights, it can gather Glimmering Gears.\n\n'
          '+3 Glimmering Gears.';
    });
  }

  bool get valleyInFight => valleyHp > 0 && valleyTurnsLeft > 0;

  bool get hasValleyInTeam =>
      activeAllies.any((npc) => npc.id == 'valley_child_of_mother_nature');

  bool get valleyAvailableForPostea =>
      unlockedNpcIds.contains('valley_child_of_mother_nature') &&
      !valleySacrificedInPostea;

  bool get posteaGrenadesEquipped =>
      starterWeapon?.id == 'postea_grenades' ||
      runBoons.contains('postea_free_vc_aoe');

  bool isPosteaEliteGuard(_GoodNpc npc) => npc.id == 'postea_elite_guard';

  bool get posteaEliteGuardInParty => activeAllies.any(isPosteaEliteGuard);

  int get posteaEliteGuardBaseMaxHp => max(
    120,
    135 + currentFloor * 18 + runGrade * 14 + playerMaxHp ~/ 5,
  ).toInt();

  int get posteaEliteGuardBaseShield =>
      max(40, 45 + currentFloor * 5 + runGrade * 6).toInt();

  int get posteaEliteGuardAttack =>
      max(16, 14 + currentFloor * 3 + runGrade * 4 + totalVc ~/ 3).toInt();

  void clearPosteaEliteGuardState() {
    posteaEliteGuardHp = 0;
    posteaEliteGuardMaxHp = 0;
    posteaEliteGuardShield = 0;
    posteaEliteGuardCriticalShieldActive = false;
  }

  void activatePosteaEliteGuard({bool refill = false}) {
    if (!posteaEliteGuardInParty) {
      clearPosteaEliteGuardState();
      return;
    }

    final oldMax = posteaEliteGuardMaxHp;
    final newMax = posteaEliteGuardBaseMaxHp;
    posteaEliteGuardMaxHp = max(posteaEliteGuardMaxHp, newMax).toInt();

    if (refill || posteaEliteGuardHp <= 0) {
      posteaEliteGuardHp = posteaEliteGuardMaxHp;
      posteaEliteGuardCriticalShieldActive = true;
    } else if (posteaEliteGuardMaxHp > oldMax) {
      posteaEliteGuardHp = min(
        posteaEliteGuardMaxHp,
        posteaEliteGuardHp + posteaEliteGuardMaxHp - oldMax,
      ).toInt();
    }

    posteaEliteGuardShield = max(
      posteaEliteGuardShield,
      posteaEliteGuardBaseShield,
    ).toInt();
  }

  int allyTrackedHp(_GoodNpc ally) {
    if (isPosteaEliteGuard(ally)) return max(0, posteaEliteGuardHp).toInt();
    if (isSmallNpc(ally)) return max(1, smallNpcActions[ally.id] ?? 1).toInt();
    return 1;
  }

  int allyTrackedMaxHp(_GoodNpc ally) {
    if (isPosteaEliteGuard(ally)) {
      return max(1, posteaEliteGuardMaxHp).toInt();
    }
    if (isSmallNpc(ally)) return max(1, allyTrackedHp(ally) + 1).toInt();
    return 1;
  }

  int allySpriteLayers(_GoodNpc ally) {
    if (isPosteaEliteGuard(ally)) return 2;
    return isSmallNpc(ally) ? 1 : 2;
  }

  bool isPosteaWeaponId(String id) =>
      id == 'postea_auto_rifle' || id == 'postea_grenades';

  bool isVillageWeaponId(String id) => id == 'combattimento_mani_nude';

  bool isStoryLockedWeaponId(String id) =>
      isPosteaWeaponId(id) || isVillageWeaponId(id);

  bool canShowStoryLockedWeapon(String id) {
    if (isPosteaWeaponId(id)) return posteaGufusEventCompleted;
    if (isVillageWeaponId(id)) {
      return unlockedTitleIds.contains('campione_primo_villaggio') ||
          unlockedWeaponIds.contains(id);
    }
    return true;
  }

  bool isPosteaCostumeId(String id) => id == 'postea_elite_armor';

  bool get hasMonsterVillageChampionTitle =>
      unlockedTitleIds.contains('campione_primo_villaggio') ||
      equippedTitleIds.contains('campione_primo_villaggio');

  void grantFirstMonsterVillageRewards() {
    final firstTitleUnlock = unlockedTitleIds.add('campione_primo_villaggio');
    var changed = firstTitleUnlock;
    if (firstTitleUnlock) {
      if (equippedTitleIds.length < titleSlotLimit) {
        equippedTitleIds.add('campione_primo_villaggio');
        applySingleTitleRunBonus(
          _allTitles.firstWhere(
            (title) => title.id == 'campione_primo_villaggio',
          ),
        );
      }
      runDamageBonus += 4;
      dungeonVolonta += 2;
      addLog(
        'Primo villaggio trovato: Titolo, Mani Nude e Swiftness Art sbloccati.',
      );
    }
    changed = unlockedWeaponIds.add('combattimento_mani_nude') || changed;
    changed = unlockedArtIds.add('swiftness_martial_art') || changed;
    if (changed) _savePermanentProgress();
  }

  void setupValleyPresence({bool training = false}) {
    valleyMaxHp = max(2, playerMaxHp * 2).toInt();
    valleyHp = valleyMaxHp;
    valleyAttack = max(8, totalDamage + 6 + currentFloor * 2).toInt();
    valleyDefense = max(2, totalDefense + 3 + currentFloor).toInt();
    valleyTurnsLeft = _random.nextInt(20) + 7;
    valleyParticipatedInFight = !training;
    valleyBloomResolvedThisFight = false;
  }

  void valleyFloorThreeEncounter() {
    if (valleySacrificedInPostea) return;
    valleyEncounterSeenThisRun = true;
    unlockedNpcIds.add('valley_child_of_mother_nature');
    final valley = npcById('valley_child_of_mother_nature');
    if (valley != null && !hasValleyInTeam) {
      addAllyToParty(valley, replaceIfFull: false);
    }
    setupValleyPresence();
    spawnEnemy(elite: true);
    textIt =
        'Valley appare al piano 3.\n\n'
        'Corpo verde, gonna di foglie, capelli verdi e una corona viva. Tre umani-pianta si piegano dietro Valley: carne aperta, fiori interni, rami e cactus.\n\n'
        'Valley resta nel fight per $valleyTurnsLeft turni.';
    textEn =
        'Valley appears on floor 3.\n\n'
        'Green body, leaf skirt, green hair and a living crown. Three plant-humans bend behind Valley: opened flesh, inner flowers, branches and cactus.\n\n'
        'Valley remains in the fight for $valleyTurnsLeft turns.';
    addLog('Valley appare al piano 3.');
  }

  void offerValleyTrainingEvent() {
    clearChoices(mode: 'event');
    textIt =
        'Allenamento con Valley.\n\n'
        'Morte reale: NO.\n'
        'HP e Oculum ripristinati a fine allenamento.\n'
        'Reward: molta EXP.\n\n'
        'Valley apre le mani: sfere compatte di natura respirano tra le dita.';
    textEn =
        'Training with Valley.\n\n'
        'Real death: NO.\n'
        'HP and Oculum refill at training end.\n'
        'Reward: high EXP.\n\n'
        'Valley opens both hands: compact nature spheres breathe between the fingers.';
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Inizia allenamento',
        labelEn: 'Start training',
        icon: Icons.spa,
        color: const Color(0xFF55B86B),
        onPressed: startValleyTraining,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Rimanda',
        labelEn: 'Postpone',
        icon: Icons.close,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt = 'Valley richiude le dita. La natura aspetta.';
            textEn = 'Valley closes the fingers. Nature waits.';
          });
        },
      ),
    );
  }

  void startValleyTraining() {
    if (!hasValleyInTeam || valleyTrainingUsedThisRun || inCombat || gameOver) {
      return;
    }
    setState(() {
      clearChoices();
      valleyTrainingActive = true;
      valleyTrainingUsedThisRun = true;
      valleyTrainingRewardClaimed = false;
      valleyBloomResolvedThisFight = true;
      valleyTrainingTurnsLeft = _random.nextInt(20) + 7;
      inCombat = true;
      enemyParty
        ..clear()
        ..add(
          _EnemyInstance(
            nameIt: 'Allenamento con Valley',
            nameEn: 'Training with Valley',
            elementId: 'flora',
            hp: max(1, playerMaxHp * 2),
            maxHp: max(1, playerMaxHp * 2),
            attack: max(6, totalDamage + currentFloor * 2 + 5),
            defense: max(2, totalDefense + currentFloor + 3),
            boss: false,
            elite: true,
            fetal: false,
            level: max(1, widget.playerLevel + 2),
            grade: max(widget.playerGrade, runGrade + 1),
            originalPower: enemyPowerScoreFromStats(
              max(1, playerMaxHp * 2),
              max(6, totalDamage + currentFloor * 2 + 5),
              max(2, totalDefense + currentFloor + 3),
            ),
          ),
        );
      syncPrimaryEnemyFromParty();
      textIt =
          'Allenamento con Valley.\n\n'
          'Morte reale: NO.\n'
          'HP e Oculum ripristinati a fine allenamento.\n'
          'Reward: molta EXP.\n'
          'Turni rimasti: $valleyTrainingTurnsLeft.';
      textEn =
          'Training with Valley.\n\n'
          'Real death: NO.\n'
          'HP and Oculum refill at training end.\n'
          'Reward: high EXP.\n'
          'Turns left: $valleyTrainingTurnsLeft.';
    });
  }

  bool canStartPosteaGufusKidnapEvent() {
    if (!runActive || inCombat || gameOver) return false;
    if (posteaGufusEventCompleted || posteaGufusEventActive) return false;
    if (valleyTrainingActive || trapMiniGameActive) return false;
    if (isBossRoom || room >= maxRooms - 1) return false;
    if (!unlockedNpcIds.contains('gufus_leviante')) return false;
    if (!gufusUsedInPreviousRun) return false;
    if (activeAllies.any((npc) => npc.id == 'gufus_leviante')) return false;
    return true;
  }

  bool tryStartPosteaGufusKidnapEvent() {
    if (!canStartPosteaGufusKidnapEvent()) return false;
    if (!chance(6)) return false;
    startPosteaGufusKidnapEvent();
    return true;
  }

  void startPosteaGufusKidnapEvent() {
    clearChoices(mode: 'event');
    posteaGufusEventActive = true;
    posteaGufusEventPhase = 'coin';
    posteaScientistTurnCounter = 0;
    posteaScientistEnhanced = false;
    textIt =
        'Il dungeon si blocca.\n\n'
        'Una moneta cade a terra. Non rimbalza. Non suona. Ti guarda.\n\n'
        'La voce del Fato sussurra attraverso il metallo: Gufus Leviante e stato rapito.\n\n'
        'La moneta e futuristica, troppo liscia per questo tempo. Sul bordo pulsa una scritta: POSTEA.\n\n'
        'Postea: una terra chiusa nel domani, rimasta incastrata in un futuro che non dovrebbe ancora esistere.';
    textEn =
        'The dungeon stops.\n\n'
        'A coin falls to the ground. It does not bounce. It makes no sound. It looks at you.\n\n'
        'Fate whispers through the metal: Gufus Leviante has been kidnapped.\n\n'
        'The coin is futuristic, too smooth for this time. One word pulses on the rim: POSTEA.\n\n'
        'Postea: a land sealed in tomorrow, trapped inside a future that should not exist yet.';
    addLog('Evento Postea: Gufus Leviante e stato rapito.');
    completeAchievement('postea_coin');
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Segui la moneta',
        labelEn: 'Follow the coin',
        icon: Icons.token,
        color: const Color(0xFF8FB7FF),
        onPressed: () => setState(startPosteaGuardFight),
      ),
    );
    saveRunCheckpoint(
      reasonIt: 'Evento Postea iniziato.',
      reasonEn: 'Postea event started.',
    );
  }

  _EnemyInstance createPosteaSoldier(int index) {
    final hp = 58 + currentFloor * 8 + runGrade * 6;
    final attack = 12 + currentFloor + runGrade;
    final defense = 15 + currentFloor ~/ 2;
    return _EnemyInstance(
      nameIt: 'Soldato di Postea ${index + 1}',
      nameEn: 'Postea Soldier ${index + 1}',
      elementId: 'postea',
      hp: hp,
      maxHp: hp,
      attack: attack,
      defense: defense,
      boss: false,
      elite: false,
      fetal: false,
      level: max(1, currentFloor),
      grade: runGrade,
      originalPower: enemyPowerScoreFromStats(hp, attack, defense),
      monsterId: 'postea_soldier',
      spriteAssetPath:
          'assets/oculum_dungeon/generated_sprites/npc/postea_elite_guard.png',
      skillIds: ['postea_coordinated_strike', 'postea_defensive_stance'],
    );
  }

  _EnemyInstance createPosteaEliteSoldier() {
    final hp = 150 + currentFloor * 14 + runGrade * 10;
    final attack = 21 + 25 + currentFloor * 2;
    final defense = 25 + currentFloor;
    return _EnemyInstance(
      nameIt: 'Soldato Elite di Postea',
      nameEn: 'Postea Elite Soldier',
      elementId: 'postea',
      hp: hp + 50,
      maxHp: hp + 50,
      attack: attack,
      defense: defense,
      boss: false,
      elite: true,
      fetal: false,
      level: 3,
      grade: max(runGrade, 1),
      originalPower: enemyPowerScoreFromStats(hp + 50, attack, defense),
      monsterId: 'postea_elite_soldier',
      spriteAssetPath:
          'assets/oculum_dungeon/generated_sprites/npc/postea_elite_guard.png',
      skillIds: [
        'postea_grenade',
        'postea_breach_blade',
        'postea_defensive_stance',
      ],
    );
  }

  _EnemyInstance createPosteaScientist() {
    final hp = 260 + currentFloor * 22 + runGrade * 18;
    final attack = 34 + currentFloor * 2 + runGrade * 2;
    final defense = 20 + currentFloor + runGrade;
    return _EnemyInstance(
      nameIt: 'Scienziato di Postea',
      nameEn: 'Postea Scientist',
      elementId: 'postea',
      hp: hp,
      maxHp: hp,
      attack: attack,
      defense: defense,
      boss: true,
      elite: true,
      fetal: false,
      level: max(3, currentFloor + 1),
      grade: max(runGrade, 1),
      originalPower: enemyPowerScoreFromStats(hp, attack, defense),
      monsterId: 'postea_scientist',
      spriteAssetPath:
          'assets/oculum_dungeon/generated_sprites/enemies/postea_scientist.png',
      skillIds: ['postea_vivisection_future', 'postea_defensive_stance'],
    );
  }

  void startPosteaGuardFight() {
    clearChoices();
    posteaGufusEventActive = true;
    posteaGufusEventPhase = 'guards';
    inCombat = true;
    enemyTurnPending = false;
    enemyWeak = 0;
    enemyBurn = 0;
    enemyBleed = 0;
    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    enemyParty
      ..clear()
      ..add(createPosteaSoldier(0))
      ..add(createPosteaSoldier(1))
      ..add(createPosteaEliteSoldier());
    syncPrimaryEnemyFromParty();
    textIt =
        'La moneta POSTEA si apre in linee azzurre.\n\n'
        'Guardie armate escono dal riflesso: 2 Soldati di Postea e 1 Soldato Elite.\n'
        'Il dungeon resta bloccato finché non cadono.';
    textEn =
        'The POSTEA coin opens into blue lines.\n\n'
        'Armed guards step out of the reflection: 2 Postea Soldiers and 1 Elite Soldier.\n'
        'The dungeon stays locked until they fall.';
    saveRunCheckpoint(
      reasonIt: 'Fight guardie Postea iniziato.',
      reasonEn: 'Postea guard fight started.',
    );
  }

  void startPosteaScientistIntro({String prefixIt = '', String prefixEn = ''}) {
    clearChoices(mode: 'event');
    posteaGufusEventActive = true;
    posteaGufusEventPhase = 'scientist_intro';
    inCombat = false;
    completeAchievement('postea_scientist_unlocked');
    textIt =
        '${prefixIt.isEmpty ? '' : '$prefixIt\n\n'}'
        'La moneta Postea si apre come un occhio meccanico.\n\n'
        'Dietro il suo riflesso, vedi Gufus Leviante sospeso in una stanza bianca.\n\n'
        'Qualcuno sta studiando cio che non avrebbe mai dovuto comprendere.';
    textEn =
        '${prefixEn.isEmpty ? '' : '$prefixEn\n\n'}'
        'The Postea coin opens like a mechanical eye.\n\n'
        'Behind its reflection, you see Gufus Leviante suspended in a white room.\n\n'
        'Someone is studying what should never have been understood.';
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Affronta lo Scienziato',
        labelEn: 'Face the Scientist',
        icon: Icons.science,
        color: const Color(0xFF8FB7FF),
        onPressed: () => setState(startPosteaScientistFight),
      ),
    );
    saveRunCheckpoint(
      reasonIt: 'Scienziato di Postea rivelato.',
      reasonEn: 'Postea Scientist revealed.',
    );
  }

  void startPosteaScientistFight() {
    clearChoices();
    posteaGufusEventActive = true;
    posteaGufusEventPhase = 'scientist';
    posteaScientistTurnCounter = 0;
    posteaScientistEnhanced = false;
    inCombat = true;
    enemyTurnPending = false;
    enemyWeak = 0;
    enemyBurn = 0;
    enemyBleed = 0;
    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    enemyParty
      ..clear()
      ..add(createPosteaScientist());
    syncPrimaryEnemyFromParty();
    textIt =
        'Scienziato di Postea.\n\n'
        'Uno scienziato di Postea, convinto che il futuro sia solo una carne da aprire, ha rapito Gufus Leviante per studiarne i geni.\n\n'
        'Se il fight supera 6 turni, qualcosa nei geni di Gufus potrebbe rispondere.';
    textEn =
        'Postea Scientist.\n\n'
        'A scientist from Postea, convinced that the future is only flesh to open, kidnapped Gufus Leviante to study its genes.\n\n'
        'If the fight lasts more than 6 turns, something in Gufus genes may answer.';
    saveRunCheckpoint(
      reasonIt: 'Fight Scienziato Postea iniziato.',
      reasonEn: 'Postea Scientist fight started.',
    );
  }

  void tickPosteaScientistEnhancement(
    List<String> reportIt,
    List<String> reportEn,
  ) {
    if (!posteaGufusEventActive ||
        posteaGufusEventPhase != 'scientist' ||
        posteaScientistEnhanced) {
      return;
    }

    posteaScientistTurnCounter++;
    if (posteaScientistTurnCounter <= 6) return;

    _EnemyInstance? scientist;
    for (final enemy in enemyParty) {
      if (enemy.hp > 0 && enemy.monsterId == 'postea_scientist') {
        scientist = enemy;
        break;
      }
    }
    if (scientist == null) return;

    posteaScientistEnhanced = true;
    scientist.maxHp += 120 + currentFloor * 8;
    scientist.hp += 120 + currentFloor * 8;
    scientist.attack += 18 + currentFloor;
    scientist.defense += 8;
    for (final skill in const [
      'postea_gene_leviante',
      'postea_levitation_field',
      'postea_vivisection_future',
    ]) {
      if (!scientist.skillIds.contains(skill)) {
        scientist.skillIds.add(skill);
      }
    }

    reportIt.add('Lo Scienziato sorride.');
    reportIt.add('Dentro le vene artificiali qualcosa levita.');
    reportIt.add('I geni di Gufus Leviante rispondono.');
    reportIt.add('Lo Scienziato di Postea si e potenziato.');
    reportEn.add('The Scientist smiles.');
    reportEn.add('Inside the artificial veins, something levitates.');
    reportEn.add('Gufus Leviante genes answer.');
    reportEn.add('The Postea Scientist has enhanced itself.');
    addLog('Lo Scienziato di Postea si e potenziato con i geni di Gufus.');
  }

  void completePosteaCombatVictory() {
    final phase = posteaGufusEventPhase;
    final defeatedIt = List<String>.from(defeatedEnemyNamesIt);
    final defeatedEn = List<String>.from(defeatedEnemyNamesEn);
    final combatExp = max(35, calculateDungeonCombatExp());
    final rewardObser = 8 + currentFloor + defeatedIt.length * 4;
    final rewardDust = phase == 'scientist' ? 5 + currentFloor ~/ 2 : 2;

    inCombat = false;
    egoWeaponStacks = 0;
    egoDefenseStacks = 0;
    killStreak++;
    combo++;
    reactionAvailable = true;
    fightsSinceTavernRest++;

    if (defeatedIt.length > 1) {
      multiEnemyBattlesWon++;
      completeAchievement('win_multi_fight');
    }

    progressQuest('kills');
    progressSkillQuest(amount: 1 + skillEventBonus('combat'));
    gainDungeonExp(combatExp, forceLevelCheck: false);
    obserInRun += rewardObser;
    ascensionDustInRun += rewardDust;

    final prefixIt =
        'Fight Postea vinto.\n\n'
        'Nemici caduti: ${defeatedIt.join(', ')}\n'
        '+$combatExp EXP\n'
        '+$rewardObser Obser\n'
        '+$rewardDust Ascension Dust.';
    final prefixEn =
        'Postea fight won.\n\n'
        'Defeated enemies: ${defeatedEn.join(', ')}\n'
        '+$combatExp EXP\n'
        '+$rewardObser Obser\n'
        '+$rewardDust Ascension Dust.';

    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    enemyParty.clear();
    syncPrimaryEnemyFromParty();

    if (phase == 'guards') {
      startPosteaScientistIntro(prefixIt: prefixIt, prefixEn: prefixEn);
      return;
    }

    resolvePosteaScientistVictory(prefixIt: prefixIt, prefixEn: prefixEn);
  }

  void grantPosteaSetRewards() {
    final changedRifle = unlockedWeaponIds.add('postea_auto_rifle');
    final changedGrenades = unlockedWeaponIds.add('postea_grenades');
    final changedCostume = unlockedCostumeIds.add('postea_elite_armor');
    final changedGuard = unlockedNpcIds.add('postea_elite_guard');
    if (changedGuard) {
      final guard = npcById('postea_elite_guard');
      if (guard != null && runActive && !gameOver) {
        final joined = addAllyToParty(guard, replaceIfFull: true, save: false);
        if (joined) {
          addLog(
            t(
              'La Guardia Élite di Postea entra nel team con il suo set completo.',
              'The Postea Elite Guard joins the team with her full set.',
            ),
          );
        }
      }
    }
    if (changedRifle || changedGrenades || changedCostume || changedGuard) {
      addLog(
        'Set di Postea sbloccato: Fucile Automatico, Granate, Armatura Élite e Guardia Élite.',
      );
    }
  }

  void addBloomedPosteaScientistAlly({required bool rare}) {
    unlockedNpcIds.add('bloomed_postea_scientist');
    final bloomed = npcById('bloomed_postea_scientist');
    if (bloomed != null) {
      addAllyToParty(bloomed, replaceIfFull: true, save: false);
    }
    if (rare) {
      completeAchievement('postea_valley_smile');
    }
  }

  String resolvePosteaValleyOutcomeIt() {
    if (!valleyAvailableForPostea) return '';

    if (posteaScientistEnhanced) {
      final roll = _random.nextInt(100) + 1;
      if (roll <= 63) {
        valleySacrificedInPostea = true;
        activeAllies.removeWhere(
          (npc) => npc.id == 'valley_child_of_mother_nature',
        );
        selectedAllyIds.remove('valley_child_of_mother_nature');
        unlockedNpcIds.remove('valley_child_of_mother_nature');
        valleyHp = 0;
        valleyTurnsLeft = 0;
        addLog('Valley si sacrifica contro lo Scienziato di Postea.');
        return '\n\nValley entra tra voi e il futuro.\n'
            'Per un istante, il dungeon profuma di radici spezzate.\n'
            'Quando la luce si spegne, siete vivi.\n'
            'Valley no.';
      }
      if (roll <= 99) {
        return '\n\nValley affonda le radici nel pavimento bianco.\n'
            'Lo Scienziato prova a calcolare la natura. La natura non risponde con i numeri.\n'
            'Valley vince.';
      }
      addBloomedPosteaScientistAlly(rare: true);
      return '\n\nValley resta immobile.\n'
          'Poi sorride.\n'
          'Uno smile troppo largo. Troppo felice. Troppo vivo.\n'
          'Lo Scienziato non muore. Sboccia.\n'
          'Valley ve lo porta davanti come un fiore sbagliato.';
    }

    if (chance(60)) {
      addBloomedPosteaScientistAlly(rare: false);
      return '\n\nLo Scienziato cade.\n'
          'Valley si china su di lui.\n'
          'Quando si rialza, sorride.\n'
          'Lo Scienziato sboccia.';
    }

    return '\n\nValley non lascia il tempo allo Scienziato di finire la frase.\n'
        'Le radici conoscono una lingua più antica della scienza.';
  }

  String resolvePosteaValleyOutcomeEn() {
    if (!valleyAvailableForPostea && !valleySacrificedInPostea) return '';
    if (valleySacrificedInPostea) {
      return '\n\nValley steps between you and the future.\n'
          'For an instant, the dungeon smells like broken roots.\n'
          'When the light fades, you are alive.\n'
          'Valley is not.';
    }
    final bloomedInParty = activeAllies.any(
      (npc) => npc.id == 'bloomed_postea_scientist',
    );
    if (bloomedInParty) {
      return '\n\nThe Scientist does not die. It blooms.\n'
          'Valley brings it before you like a wrong flower.';
    }
    return '\n\nValley intervenes and saves the party.';
  }

  void resolvePosteaScientistVictory({
    String prefixIt = '',
    String prefixEn = '',
  }) {
    final valleyIt = resolvePosteaValleyOutcomeIt();
    final valleyEn = resolvePosteaValleyOutcomeEn();
    posteaGufusEventCompleted = true;
    posteaGufusEventActive = false;
    posteaGufusEventPhase = '';
    completeAchievement('postea_gufus_rescue');
    if (posteaScientistEnhanced) {
      completeAchievement('postea_leviante_genes');
    }
    grantPosteaSetRewards();
    unlockedNpcIds.add('gufus_leviante');
    textIt =
        '${prefixIt.isEmpty ? '' : '$prefixIt\n\n'}'
        'Gufus Leviante e salvo.\n\n'
        'Memoria di Postea: Gufus ricorda per un secondo un futuro in cui non e mai stato libero.\n'
        '+1 azione quando Gufus entra nel party.\n\n'
        'Ricompensa: Set Elite di Postea sbloccato.\n'
        '- Fucile Automatico di Postea\n'
        '- Granate di Postea\n'
        '- Armatura Élite Postea con Scudo Critico\n'
        '- Guardia Élite di Postea nel team.'
        '$valleyIt';
    textEn =
        '${prefixEn.isEmpty ? '' : '$prefixEn\n\n'}'
        'Gufus Leviante is safe.\n\n'
        'Memory of Postea: for one second, Gufus remembers a future where it was never free.\n'
        '+1 action when Gufus joins the party.\n\n'
        'Reward: Postea Elite Set unlocked.\n'
        '- Postea Automatic Rifle\n'
        '- Postea Grenades\n'
        '- Postea Elite Armor with Critical Shield\n'
        '- Postea Elite Guard in the team.'
        '$valleyEn';
    addLog('Rapimento di Gufus Leviante completato: set di Postea sbloccato.');
    _savePermanentProgress();
    saveRunCheckpoint(
      reasonIt: 'Evento Postea completato.',
      reasonEn: 'Postea event completed.',
    );
  }

  void exploreRoom() {
    if (!runActive || inCombat || gameOver) return;
    if (posteaGufusEventActive) {
      setState(() {
        textIt =
            'Il dungeon resta bloccato dalla moneta POSTEA. Risolvi l evento prima di avanzare.';
        textEn =
            'The dungeon remains locked by the POSTEA coin. Resolve the event before moving on.';
      });
      return;
    }

    setState(() {
      clearChoices();

      if (nextRoomSafe) {
        nextRoomSafe = false;
        safeRoomEvent();
        gainDungeonExp(25 + currentFloor * 5, forceLevelCheck: false);
        return;
      }

      room++;
      merchantActionUsedThisRoom = false;
      merchantGearsSoldThisRoom = false;
      peacefulMonstersMet = false;
      relicSkillUsesThisRoom = 0;
      blacksmithActionUsedThisRoom = false;
      dropActionUsedThisRoom = false;
      restActionUsedThisRoom = false;
      if (currentFloorStart != currentFloor &&
          vervainBuffFloor > 0 &&
          vervainBuffFloor != currentFloor) {
        vervainBuffFloor = 0;
        dungeonResilienza = max(0, dungeonResilienza - 5).toInt();
        dungeonVolonta = max(0, dungeonVolonta - 5).toInt();
        dungeonMateria = max(0, dungeonMateria - 5).toInt();
        dungeonOculum = max(0, dungeonOculum - 5).toInt();
      }
      if (currentFloorStart != currentFloor) {
        titleEventUsedThisFloor = false;
      }
      currentFloorStart = currentFloor;
      dungeonFloor = currentFloor;
      evolvePrincipianteForCurrentFloor();
      if (maybeFloorSaveEvent()) return;
      if (maybeAwardFloorRandomTitle()) return;
      roomsWithoutDamage++;

      if (!floorZeroCompleted) {
        gainDungeonExp(6, forceLevelCheck: false);
        maybeEarlyAscensionDustFind();
        floorZeroEvent();
        return;
      }

      gainDungeonExp(
        12 + currentFloor * 8 + runGrade * 4,
        forceLevelCheck: false,
      );
      maybeEarlyAscensionDustFind();

      if (runHealOnExplore > 0) {
        playerHp = min(playerMaxHp, playerHp + runHealOnExplore);
      }

      if (tryTitleTriggeredEvent()) return;
      if (tryExpertOculumEvent()) return;
      if (tryCalendarPhaseEvent()) return;
      if (tryStartPosteaGufusKidnapEvent()) return;
      if (tryOculumShieldRareEvent()) return;
      if (tryKarmaChoiceEvent()) return;
      if (tryGradeScaledEvent()) return;

      if (room >= maxRooms) {
        winRun();
        return;
      }

      if (isBeforeBossRoom && _random.nextInt(100) < 72) {
        dungeonExp = max(dungeonExp, expToNextDungeonLevel);
        offerDungeonLevelUp(
          reasonIt: 'Senti un boss vicino. Il dungeon ti concede un respiro.',
          reasonEn: 'You feel a boss nearby. The dungeon grants you a breath.',
        );
        return;
      }

      if (dungeonExp >= expToNextDungeonLevel && chance(48)) {
        offerDungeonLevelUp(
          reasonIt: 'La tua esperienza nella run prende forma.',
          reasonEn: 'Your experience inside the run takes shape.',
        );
        return;
      }

      if (isBossRoom) {
        spawnEnemy(boss: true);
        return;
      }

      if (currentFloor == 3 &&
          !valleySacrificedInPostea &&
          !valleyEncounterSeenThisRun &&
          chance(35)) {
        valleyFloorThreeEncounter();
        return;
      }

      if (hasValleyInTeam &&
          !valleyTrainingUsedThisRun &&
          !valleyTrainingActive &&
          chance(8)) {
        offerValleyTrainingEvent();
        return;
      }

      if (currentFloor >= 2 && chance(mapRevealed ? 10 : 7)) {
        gainKoobaGearsForPeacefulRoom();
        monsterVillageEvent();
        return;
      }

      final roll = _random.nextInt(100) + 1;
      final mapBonus = mapRevealed ? 8 : 0;

      if (!criticalShieldActive && currentFloor >= 2 && chance(4)) {
        criticalShieldEvent();
        return;
      }

      if (roll <= 21) {
        spawnEnemy();
      } else if (roll <= 29) {
        spawnEnemy(elite: true);
      } else if (roll <= 35 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        treasureEvent();
      } else if (roll <= 38 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        peacefulMonstersEvent();
      } else if (roll <= 40 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        evonestTempleEvent();
      } else if (roll <= 45 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        drownedTradeCityEvent();
      } else if (roll <= 50 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        asherFireEvent();
      } else if (roll <= 54 + mapBonus) {
        if (isInLastSixteenRooms) {
          gainKoobaGearsForPeacefulRoom();
          hideanAllianceEvent();
        } else {
          gainKoobaGearsForPeacefulRoom();
          oculumLibraryEvent();
        }
      } else if (roll <= 58 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        occultVaultEvent();
      } else if (roll <= 62 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        ascensionChoiceEvent();
      } else if (roll <= 66 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        alchemistSatchelEvent();
      } else if (roll <= 70 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        forgottenArmoryEvent();
      } else if (roll <= 74 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        oculumLibraryEvent();
      } else if (roll <= 78 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        merchantEvent();
      } else if (roll <= 82 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        blacksmithEvent();
      } else if (roll <= 85 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        tavernEvent();
      } else if (roll <= 88 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        quietCampEvent();
      } else if (roll <= 91 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        mirrorOfTheRunEvent();
      } else if (roll <= 94 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        woundedAllyEvent();
      } else if (roll <= 96 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        cursedObserChestEvent();
      } else if (roll <= 98 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        elementalWellEvent();
      } else if (roll <= 99 + mapBonus) {
        gainKoobaGearsForPeacefulRoom();
        arcanePedestalEvent();
      } else {
        gainKoobaGearsForPeacefulRoom();
        shrineEvent();
      }
    });
  }

  List<_GradeEventDef> gradeEventDefs() {
    return const [
      _GradeEventDef(
        id: 'g1_broken_formula_desk',
        grade: 1,
        titleIt: 'Grado I - Banco delle Formule Rotte',
        titleEn: 'Grade I - Broken Formula Desk',
        descIt:
            'Un banco scolastico è inciso come una scheda: statistiche a sinistra, paura a destra.',
        descEn:
            'A school desk is carved like a character sheet: stats on the left, fear on the right.',
        icon: Icons.science,
      ),
      _GradeEventDef(
        id: 'g1_true_dice_room',
        grade: 1,
        titleIt: 'Grado I - Sala dei Dadi Veri',
        titleEn: 'Grade I - True Dice Room',
        descIt:
            'I dadi cadono da soli e pretendono che tu scelga prima il ruolo, poi il numero.',
        descEn:
            'Dice fall by themselves and demand that you choose the role before the number.',
        icon: Icons.casino,
      ),
      _GradeEventDef(
        id: 'g1_non_newtonian_puddle',
        grade: 1,
        titleIt: 'Grado I - Pozza Non Newtoniana',
        titleEn: 'Grade I - Non-Newtonian Puddle',
        descIt:
            'La stanza è morbida se cammini piano, durissima se provi a scappare.',
        descEn:
            'The room is soft if you walk slowly, brutally hard if you try to run.',
        icon: Icons.water_drop,
      ),
      _GradeEventDef(
        id: 'g2_blue_automaton_gym',
        grade: 2,
        titleIt: 'Grado II - Palestra degli Automi Blu',
        titleEn: 'Grade II - Blue Automaton Gym',
        descIt:
            'Sagome robotiche blu ripetono esercizi sbagliati con convinzione assoluta.',
        descEn:
            'Blue robotic silhouettes repeat wrong drills with absolute confidence.',
        icon: Icons.fitness_center,
      ),
      _GradeEventDef(
        id: 'g2_page_archive',
        grade: 2,
        titleIt: 'Grado II - Archivio delle Pagine',
        titleEn: 'Grade II - Page Archive',
        descIt:
            'Scaffali ordinati come schede: Art, Titoli, Skill e note di un master stanco.',
        descEn:
            'Shelves ordered like sheets: Arts, Titles, Skills and notes from a tired GM.',
        icon: Icons.library_books,
      ),
      _GradeEventDef(
        id: 'g2_jrpg_merchant',
        grade: 2,
        titleIt: 'Grado II - Mercante da Menu JRPG',
        titleEn: 'Grade II - JRPG Menu Merchant',
        descIt:
            'Ha tre righe di dialogo, quattro prezzi e un sorriso da boss opzionale.',
        descEn:
            'He has three dialogue lines, four prices and the smile of an optional boss.',
        icon: Icons.storefront,
      ),
      _GradeEventDef(
        id: 'g3_tactical_rift',
        grade: 3,
        titleIt: 'Grado III - Fenditura Tattica',
        titleEn: 'Grade III - Tactical Rift',
        descIt:
            'La mappa diventa a caselle: il party, il turno e la posizione contano davvero.',
        descEn:
            'The map turns grid-like: party, turn order and position actually matter.',
        icon: Icons.grid_view,
      ),
      _GradeEventDef(
        id: 'g3_time_classroom',
        grade: 3,
        titleIt: 'Grado III - Aula del Tempo',
        titleEn: 'Grade III - Time Classroom',
        descIt:
            'La lavagna ripete l ultima azione con un errore segnato in blu.',
        descEn:
            'The blackboard repeats the last action with one blue-marked mistake.',
        icon: Icons.history,
      ),
      _GradeEventDef(
        id: 'g3_monster_role_table',
        grade: 3,
        titleIt: 'Grado III - Tavolo dei Ruoli Mostruosi',
        titleEn: 'Grade III - Monster Role Table',
        descIt:
            'Mostri piccoli discutono di tank, striker, support e di chi deve aprire la porta.',
        descEn:
            'Small monsters discuss tank, striker, support and who should open the door.',
        icon: Icons.groups,
      ),
      _GradeEventDef(
        id: 'g4_postea_runic_foundry',
        grade: 4,
        titleIt: 'Grado IV - Fonderia Runica di Postea',
        titleEn: 'Grade IV - Postea Runic Foundry',
        descIt:
            'Metallo futuro, rune vecchie e stampi militari respirano sotto il pavimento.',
        descEn:
            'Future metal, old runes and military molds breathe under the floor.',
        icon: Icons.precision_manufacturing,
      ),
      _GradeEventDef(
        id: 'g4_kingi_blue_relay',
        grade: 4,
        titleIt: 'Grado IV - Relè Blu di Kingi',
        titleEn: 'Grade IV - Kingi Blue Relay',
        descIt:
            'Un relè blu scuro prova a sembrare intelligente. Quasi ci riesce.',
        descEn:
            'A dark blue relay tries to look intelligent. It nearly succeeds.',
        icon: Icons.memory,
      ),
      _GradeEventDef(
        id: 'g4_defiled_checkpoint',
        grade: 4,
        titleIt: 'Grado IV - Checkpoint Defiled',
        titleEn: 'Grade IV - Defiled Checkpoint',
        descIt:
            'Una porta controlla nome pagina, Art equipaggiata e quanto metallo porti.',
        descEn:
            'A door checks page name, equipped Art and how much metal you carry.',
        icon: Icons.key,
      ),
      _GradeEventDef(
        id: 'g5_dungeon_core_menu',
        grade: 5,
        titleIt: 'Grado V - Menu del Nucleo Dungeon',
        titleEn: 'Grade V - Dungeon Core Menu',
        descIt:
            'Il nucleo apre un menu da boss finale: equip, party, skill, rischio.',
        descEn: 'The core opens a final-boss menu: equip, party, skill, risk.',
        icon: Icons.blur_on,
      ),
      _GradeEventDef(
        id: 'g5_party_fate',
        grade: 5,
        titleIt: 'Grado V - Fato del Party',
        titleEn: 'Grade V - Party Fate',
        descIt:
            'Ogni alleato appare come una statistica viva. Ogni assenza pesa il doppio.',
        descEn:
            'Every ally appears as a living stat. Every absence weighs twice as much.',
        icon: Icons.diversity_3,
      ),
      _GradeEventDef(
        id: 'g5_emblem_forge',
        grade: 5,
        titleIt: 'Grado V - Forgia degli Emblemi',
        titleEn: 'Grade V - Emblem Forge',
        descIt:
            'La stanza non premia la forza: premia build leggibili, rischi chiari e scelte sporche.',
        descEn:
            'The room does not reward strength: it rewards readable builds, clear risks and dirty choices.',
        icon: Icons.auto_awesome,
      ),
    ];
  }

  bool tryGradeScaledEvent() {
    if (!floorZeroCompleted || inCombat || gameOver || currentFloor <= 0) {
      return false;
    }
    if (!chance(5 + runGrade + currentFloor ~/ 3)) return false;
    final pool =
        gradeEventDefs()
            .where((event) => event.grade <= runGrade)
            .where((event) => !gradeEventsSeenThisRun.contains(event.id))
            .toList()
          ..shuffle(_random);
    if (pool.isEmpty) return false;
    showGradeScaledEvent(pool.first);
    return true;
  }

  void showGradeScaledEvent(_GradeEventDef event) {
    gradeEventsSeenThisRun.add(event.id);
    clearChoices(mode: 'event');
    final gradeLabel = t('Grado ${event.grade}', 'Grade ${event.grade}');
    textIt =
        '${event.titleIt}\n\n${event.descIt}\n\nEvento scalato sul $gradeLabel: scegli approccio come in una scheda RPG.';
    textEn =
        '${event.titleEn}\n\n${event.descEn}\n\nEvent scaled on $gradeLabel: choose an approach like on an RPG sheet.';
    addLog(
      t('Evento Grado: ${event.titleIt}.', 'Grade Event: ${event.titleEn}.'),
    );

    eventChoices.addAll([
      _DungeonChoice(
        labelIt: 'Approccio prudente',
        labelEn: 'Careful approach',
        icon: Icons.shield,
        color: Colors.lightBlueAccent,
        onPressed: () => resolveGradeScaledEvent(event, 'safe'),
      ),
      _DungeonChoice(
        labelIt: 'Approccio tecnico',
        labelEn: 'Technical approach',
        icon: event.icon,
        color: widget.tertiaryColor,
        onPressed: () => resolveGradeScaledEvent(event, 'technical'),
      ),
      _DungeonChoice(
        labelIt: 'Rischia come JRPG',
        labelEn: 'Take the JRPG risk',
        icon: Icons.flash_on,
        color: Colors.orangeAccent,
        onPressed: () => resolveGradeScaledEvent(event, 'risk'),
      ),
    ]);
  }

  void resolveGradeScaledEvent(_GradeEventDef event, String approach) {
    setState(() {
      clearChoices();
      final grade = event.grade;
      final base = 6 + currentFloor * 2 + grade * 5;
      final posteaEvent =
          event.id.contains('postea') ||
          event.id.contains('defiled') ||
          event.id.contains('foundry');
      final schoolEvent =
          event.id.contains('formula') ||
          event.id.contains('newtonian') ||
          event.id.contains('classroom');
      final kingiEvent =
          event.id.contains('kingi') ||
          event.id.contains('blue') ||
          event.id.contains('automaton');
      final artEvent =
          event.id.contains('archive') ||
          event.id.contains('emblem') ||
          event.id.contains('core');

      if (approach == 'safe') {
        final shield = eventShieldGain(base + totalDefense ~/ 4);
        final heal = min(playerMaxHp - playerHp, 4 + grade * 4 + currentFloor);
        gainPlayerShield(shield);
        playerHp = min(playerMaxHp, playerHp + max(0, heal));
        dungeonExp += 18 + grade * 8;
        if (schoolEvent) dungeonResilienza += grade;
        textIt =
            '${event.titleIt}\n\nApproccio prudente.\n+$shield Scudo, +${max(0, heal)} HP, +${18 + grade * 8} EXP.${schoolEvent ? '\nLa scheda scolastica si allinea: +$grade Resilienza.' : ''}';
        textEn =
            '${event.titleEn}\n\nCareful approach.\n+$shield Shield, +${max(0, heal)} HP, +${18 + grade * 8} EXP.${schoolEvent ? '\nThe school sheet aligns: +$grade Resilience.' : ''}';
      } else if (approach == 'technical') {
        final statGain = grade + currentFloor ~/ 4;
        dungeonVolonta += statGain;
        dungeonMateria += statGain;
        runDefenseBonus += grade;
        runDamageBonus += grade;
        if (kingiEvent) {
          gainOculumCharges(1);
          unlockedArtIds.add('kingi_blue_art');
        }
        if (posteaEvent) {
          final kg = 1 + _random.nextInt(6);
          posteaRunicMetalKg += kg;
          unlockedArtIds.add('defiled_postea_art');
        }
        if (artEvent) {
          tryUnlockRandomArt();
        }
        textIt =
            '${event.titleIt}\n\nApproccio tecnico.\n+$statGain Volontà e Materia, +$grade danni e difesa run.'
            '${kingiEvent ? '\nRelè blu stabilizzato: Kingi Art sbloccata e +1 Oculum carica/max.' : ''}'
            '${posteaEvent ? '\nMetallo Runico Postea trovato: ora hai $posteaRunicMetalLabel.' : ''}'
            '${artEvent ? '\nL archivio prova a sbloccare una nuova Art.' : ''}';
        textEn =
            '${event.titleEn}\n\nTechnical approach.\n+$statGain Will and Materia, +$grade run damage and defense.'
            '${kingiEvent ? '\nBlue relay stabilized: Kingi Art unlocked and +1 Oculum charge/max.' : ''}'
            '${posteaEvent ? '\nPostea Runic Metal found: you now have $posteaRunicMetalLabel.' : ''}'
            '${artEvent ? '\nThe archive tries to unlock a new Art.' : ''}';
      } else {
        final rewardObser = 8 + grade * 5 + currentFloor;
        final rewardDust = 1 + grade ~/ 2;
        obserInRun += rewardObser;
        ascensionDustInRun += rewardDust;
        runCritBonus += 2 + grade;
        if (posteaEvent) posteaRunicMetalKg += min(6, 2 + grade);
        if (grade >= 4 || chance(35 + grade * 8)) {
          textIt =
              '${event.titleIt}\n\nRischio JRPG.\n+$rewardObser Obser, +$rewardDust Dust, +${2 + grade} critico.'
              '${posteaEvent ? '\nLa stanza lascia metallo: $posteaRunicMetalLabel.' : ''}\n\nIl rischio chiama un fight.';
          textEn =
              '${event.titleEn}\n\nJRPG risk.\n+$rewardObser Obser, +$rewardDust Dust, +${2 + grade} critical.'
              '${posteaEvent ? '\nThe room leaves metal: $posteaRunicMetalLabel.' : ''}\n\nThe risk calls a fight.';
          spawnEnemy(elite: grade >= 2, boss: grade >= 5 && chance(25));
          return;
        }
        textIt =
            '${event.titleIt}\n\nRischio JRPG riuscito.\n+$rewardObser Obser, +$rewardDust Dust, +${2 + grade} critico. Nessun fight immediato.';
        textEn =
            '${event.titleEn}\n\nJRPG risk succeeded.\n+$rewardObser Obser, +$rewardDust Dust, +${2 + grade} critical. No immediate fight.';
      }

      progressQuest('treasure');
      progressSkillQuest(amount: grade);
      saveRunCheckpoint(
        reasonIt: 'Evento Grado registrato.',
        reasonEn: 'Grade event recorded.',
      );
    });
  }

  bool tryCalendarPhaseEvent() {
    final phase = cyclePhase().id;
    if (phase == 'safe_monster' && chance(7 + currentFloor)) {
      peacefulMonstersEvent();
      return true;
    }
    if (phase == 'little_breath' && chance(5 + currentFloor)) {
      titleWhisperEvent();
      return true;
    }
    if (phase == 'moon' && chance(8)) {
      safeRoomEvent();
      return true;
    }
    if (phase == 'illness' && chance(6 + currentFloor)) {
      trapEvent();
      return true;
    }
    if (phase == 'fertile_rain' && chance(6)) {
      alchemistSatchelEvent();
      return true;
    }
    if (phase == 'null' && chance(5 + currentFloor ~/ 2)) {
      spawnEnemy(elite: currentFloor >= 4);
      return true;
    }
    return false;
  }

  bool tryOculumShieldRareEvent() {
    if (currentFloor < 2 || inCombat || gameOver) return false;
    final karmaPressure = dungeonKarma.abs().clamp(0, 6).toInt();
    if (!chance(4 + currentFloor ~/ 2 + karmaPressure)) return false;
    oculumShieldRareEvent();
    return true;
  }

  bool tryKarmaChoiceEvent() {
    if (inCombat || gameOver) return false;
    final titleBonus = equippedTitleIds.contains('mille_lacrime') ? 3 : 0;
    if (!chance(7 + currentFloor ~/ 2 + titleBonus)) return false;
    karmaCrossroadsEvent();
    return true;
  }

  void oculumShieldRareEvent() {
    clearChoices(mode: 'event');
    textIt =
        'Evento raro — Palpebra dello Scudo Oculum.\n\n'
        'Un occhio vivo galleggia dentro una bolla trasparente. Non protegge la pelle: protegge la parte di te che guarda.';
    textEn =
        'Rare Event — Oculum Shield Eyelid.\n\n'
        'A living eye floats inside a transparent bubble. It does not protect skin: it protects the part of you that watches.';

    eventChoices.addAll([
      _DungeonChoice(
        labelIt: 'Accetta la palpebra',
        labelEn: 'Accept the eyelid',
        icon: Icons.visibility,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            final shield = (12 + currentFloor * 3 + max(0, dungeonKarma))
                .toInt();
            gainOculumShield(shield, expandMaximum: true);
            textIt =
                'Accetti la palpebra senza forzarla.\n+$shield Scudo Oculum.\nKarma +1.';
            textEn =
                'You accept the eyelid without forcing it.\n+$shield Oculum Shield.\nKarma +1.';
            changeDungeonKarma(1);
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Forza il riflesso',
        labelEn: 'Force the reflection',
        icon: Icons.bolt,
        color: Colors.deepPurpleAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            final shield = 28 + currentFloor * 5;
            final wound = max(6, playerMaxHp ~/ 8);
            gainOculumShield(shield, expandMaximum: true);
            applyPlayerDamage(wound, ignoreShields: true);
            textIt =
                'Forzi il riflesso. Funziona, ma l occhio ti graffia da dentro.\n+$shield Scudo Oculum.\n-$wound HP.\nKarma -2.';
            textEn =
                'You force the reflection. It works, but the eye scratches you from inside.\n+$shield Oculum Shield.\n-$wound HP.\nKarma -2.';
            changeDungeonKarma(-2);
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Donalo alla stanza',
        labelEn: 'Give it to the room',
        icon: Icons.volunteer_activism,
        color: Colors.tealAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            final heal = 10 + currentFloor * 2;
            final shield = 6 + currentFloor;
            playerHp = min(playerMaxHp, playerHp + heal);
            gainOculumShield(shield, expandMaximum: true);
            textIt =
                'Doni parte del riflesso alla stanza. Il dungeon non capisce la gentilezza, ma la registra.\n+$heal HP, +$shield Scudo Oculum.\nKarma +2.';
            textEn =
                'You give part of the reflection to the room. The dungeon does not understand kindness, but records it.\n+$heal HP, +$shield Oculum Shield.\nKarma +2.';
            changeDungeonKarma(2);
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Tocca la pupilla rotta',
        labelEn: 'Touch the broken pupil',
        icon: Icons.warning_amber,
        color: Colors.redAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            final loss = min(playerOculumShield, 10 + currentFloor * 2);
            final wound = 8 + currentFloor * 3;
            playerOculumShield -= loss;
            applyPlayerDamage(wound, ignoreOculumShield: true);
            textIt =
                'Scelta sbagliata. La pupilla era una trappola.\n-$loss Scudo Oculum, danno in arrivo $wound.\nKarma -1.';
            textEn =
                'Wrong choice. The pupil was a trap.\n-$loss Oculum Shield, incoming damage $wound.\nKarma -1.';
            changeDungeonKarma(-1);
          });
        },
      ),
    ]);
  }

  void karmaCrossroadsEvent() {
    clearChoices(mode: 'event');
    textIt =
        'Evento — Bilancia nel Buio.\n\n'
        'Tre piatti galleggiano: uno chiede rinuncia, uno chiede furto, uno mente apertamente. Le scelte sbagliate non sono bloccate.';
    textEn =
        'Event — Scale in the Dark.\n\n'
        'Three plates float: one asks renunciation, one asks theft, one openly lies. Wrong choices are not blocked.';

    eventChoices.addAll([
      _DungeonChoice(
        labelIt: 'Restituisci gli Obser incisi',
        labelEn: 'Return the engraved Obser',
        icon: Icons.undo,
        color: Colors.lightGreenAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            final paid = min(obserInRun, 4 + currentFloor);
            obserInRun -= paid;
            final shield = 8 + paid * 2;
            gainOculumShield(shield, expandMaximum: true);
            textIt =
                'Rimetti gli Obser dove il dungeon li aveva persi.\n-$paid Obser, +$shield Scudo Oculum.\nKarma +2.';
            textEn =
                'You put the Obser back where the dungeon lost them.\n-$paid Obser, +$shield Oculum Shield.\nKarma +2.';
            changeDungeonKarma(2);
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Rubali e sorridi',
        labelEn: 'Steal them and smile',
        icon: Icons.payments,
        color: Colors.amber,
        onPressed: () {
          setState(() {
            clearChoices();
            final gain = 7 + currentFloor;
            obserInRun += gain;
            runDamageBonus += 1;
            textIt =
                'Li prendi senza chiedere. La stanza si ricorda il sorriso.\n+$gain Obser, +1 danno run.\nKarma -2.';
            textEn =
                'You take them without asking. The room remembers the smile.\n+$gain Obser, +1 run damage.\nKarma -2.';
            changeDungeonKarma(-2);
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Leggi la bugia',
        labelEn: 'Read the lie',
        icon: Icons.menu_book,
        color: Colors.cyanAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            final success = dungeonOculum + totalCm ~/ 6 + dungeonKarma >= 8;
            if (success) {
              dungeonExp += 22 + currentFloor * 6;
              mapRevealed = true;
              textIt =
                  'La bugia era scritta al contrario. La leggi senza obbedire.\nMappa rivelata, EXP bonus.\nKarma +1.';
              textEn =
                  'The lie was written backwards. You read it without obeying.\nMap revealed, bonus EXP.\nKarma +1.';
              changeDungeonKarma(1);
            } else {
              final wound = 5 + currentFloor * 2;
              applyPlayerDamage(wound, ignoreShields: true);
              textIt =
                  'Scelta sbagliata. La bugia legge te.\n-$wound HP.\nKarma -1.';
              textEn =
                  'Wrong choice. The lie reads you.\n-$wound HP.\nKarma -1.';
              changeDungeonKarma(-1);
            }
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Spacca la bilancia',
        labelEn: 'Break the scale',
        icon: Icons.close,
        color: Colors.redAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            final damage = 10 + currentFloor * 3;
            final hit = applyPlayerDamage(damage);
            threat += 1;
            textIt =
                'Scelta sbagliata. La bilancia era un osso portante.\n-${hit['hp']} HP, ${hit['oculumShield']} Scudo Oculum e ${hit['shield']} Scudo assorbiti.\nMinaccia +1, Karma -3.';
            textEn =
                'Wrong choice. The scale was a load-bearing bone.\n-${hit['hp']} HP, ${hit['oculumShield']} Oculum Shield and ${hit['shield']} Shield absorbed.\nThreat +1, Karma -3.';
            changeDungeonKarma(-3);
          });
        },
      ),
    ]);
  }

  bool tryTitleTriggeredEvent() {
    if (titleEventUsedThisFloor || inCombat || gameOver) return false;

    // Blind spot / neutral: floor 3 minor Oculian.
    if (currentFloor == 3 &&
        !minorOculianSeen &&
        (equippedTitleIds.contains('occhio_del_nido') ||
            equippedTitleIds.contains('palpebra_di_sale') ||
            equippedTitleIds.contains('mille_lacrime')) &&
        chance(18)) {
      titleEventUsedThisFloor = true;
      minorOculianSeen = true;
      blindSpotTitleEventsSeen++;
      completeAchievement('minor_oculian_watcher');
      spawnMinorOculian();
      return true;
    }

    // Floor 6 child event: neutral/positive, unlocks weak NPC.
    if (currentFloor == 6 &&
        !thousandEyesChildSeen &&
        (equippedTitleIds.contains('mille_lacrime') ||
            equippedTitleIds.contains('nervo_di_luna') ||
            equippedTitleIds.contains('stella_nascosta')) &&
        chance(22)) {
      titleEventUsedThisFloor = true;
      thousandEyesChildSeen = true;
      positiveTitleEventsSeen++;
      thousandEyesChildEvent();
      return true;
    }

    // Positive nature/moon/star whispers.
    if ((equippedTitleIds.contains('giardino_nel_torace') ||
            equippedTitleIds.contains('nervo_di_luna') ||
            equippedTitleIds.contains('fame_di_stelle')) &&
        chance(10 + currentFloor)) {
      titleEventUsedThisFloor = true;
      positiveTitleEventsSeen++;
      titleWhisperEvent();
      return true;
    }

    return false;
  }

  void titleWhisperEvent() {
    clearChoices(mode: 'event');

    if (equippedTitleIds.contains('giardino_nel_torace')) {
      final heal = 10 + currentFloor * 2 + titleLevel('giardino_nel_torace');
      playerHp = min(playerMaxHp, playerHp + heal);
      runHealOnExplore += 1;
      textIt =
          'Evento Titolo — Giardino nel Torace.\nRadici gentili ti ricuciono.\n+$heal HP\n+1 cura/esplora.';
      textEn =
          'Title Event — Garden in the Chest.\nGentle roots stitch you.\n+$heal HP\n+1 heal/explore.';
      return;
    }

    if (equippedTitleIds.contains('nervo_di_luna')) {
      criticalShieldActive = true;
      gainPlayerShield(eventShieldGain(16 + currentFloor * 2));
      textIt =
          'Evento Titolo — Nervo di Luna.\nUna luna bassa ti copre la palpebra.\nScudo Critico attivo.';
      textEn =
          'Title Event — Moon Nerve.\nA low moon covers your eyelid.\nCritical Shield active.';
      return;
    }

    runCritBonus += 5 + currentFloor;
    runDamageBonus += 1;
    textIt =
        'Evento Titolo — Fame di Stelle.\nUna stella piccola ti morde.\n+critico e +1 danno.';
    textEn =
        'Title Event — Star Hunger.\nA small star bites you.\n+critical and +1 damage.';
  }

  void spawnMinorOculian() {
    if (hasOculianPact) {
      inCombat = false;
      enemyParty.clear();
      syncPrimaryEnemyFromParty();
      final ally = npcById('minor_oculian_watcher');
      if (ally != null) {
        unlockedNpcIds.add(ally.id);
        addAllyToParty(ally, replaceIfFull: true, save: false);
      }
      oculianAllianceActive = true;
      oculumCharges = min(oculumMaxCharges, oculumCharges + 1).toInt();
      textIt =
          'Punto cieco del Titolo.\n\n'
          'Un Oculiano Minore ti riconosce dal patto viola.\n'
          'Non combatte: si mette accanto al party e ricarica 1 Oculum.';
      textEn =
          'Title Blind Spot.\n\n'
          'A Minor Oculian recognizes your purple pact.\n'
          'It does not fight: it joins the party side and restores 1 Oculum.';
      saveRunCheckpoint(
        reasonIt: 'Patto Oculiano: Oculiano Minore convertito in alleato.',
        reasonEn: 'Oculian pact: Minor Oculian converted into ally.',
      );
      return;
    }

    inCombat = true;
    final enemyHp = 70 + currentFloor * 18;
    final enemyAttack = 8 + currentFloor * 3;
    final enemyDefense = 3 + currentFloor;
    enemyParty
      ..clear()
      ..add(
        _EnemyInstance(
          nameIt: 'Oculiano Minore che Osserva',
          nameEn: 'Watching Minor Oculian',
          elementId: 'oculum',
          hp: enemyHp,
          maxHp: enemyHp,
          attack: enemyAttack,
          defense: enemyDefense,
          boss: false,
          elite: true,
          fetal: false,
          level: max(1, currentFloor + 1),
          grade: max(0, runGrade + 1),
          originalPower: enemyPowerScoreFromStats(
            enemyHp,
            enemyAttack,
            enemyDefense,
          ),
        ),
      );
    syncPrimaryEnemyFromParty();
    textIt =
        'Punto cieco del Titolo.\n\n'
        '“Un Oculiano minore ti osserva.”\n'
        'Non grida. Non corre. Ti studia e poi apre il mantello.';
    textEn =
        'Title Blind Spot.\n\n'
        '“A minor Oculian watches you.”\n'
        'It does not scream. It does not run. It studies you and opens the mantle.';
  }

  void thousandEyesChildEvent() {
    clearChoices(mode: 'event');
    completeAchievement('thousand_eyes_child');
    unlockedNpcIds.add('thousand_eyes_child');
    _savePermanentProgress();

    textIt =
        'Evento Titolo — Bambino dai Mille Occhi.\n\n'
        '“Un bambino dai mille occhi perde così tante lacrime.”\n'
        'Non sembra un nemico. Sembra un avvertimento piccolo.\n'
        'NPC sbloccato: Bambino dai Mille Occhi.';
    textEn =
        'Title Event — Thousand-Eyed Child.\n\n'
        '“A child with a thousand eyes loses so many tears.”\n'
        'It does not seem like an enemy. It seems like a small warning.\n'
        'NPC unlocked: Thousand-Eyed Child.';
  }

  void floorZeroEvent() {
    final roll = _random.nextInt(100) + 1;

    if (room >= 7) {
      floorZeroCompleted = true;
      completeAchievement('floor_zero_clear');
      unlockRandomTitle();
      textIt =
          'Piano 0 completato.\n\n'
          'Sette stanze piccole, nessuna gloria enorme.\n'
          'Il dungeon vero apre il primo occhio.';
      textEn =
          'Floor 0 completed.\n\n'
          'Seven small rooms, no enormous glory.\n'
          'The real dungeon opens its first eye.';
      return;
    }

    if (roll <= 28) {
      final heal = 4 + titleResBonus;
      playerHp = min(playerMaxHp, playerHp + heal);
      textIt = 'Piano 0 — Nicchia tiepida.\n+$heal HP.';
      textEn = 'Floor 0 — Warm niche.\n+$heal HP.';
    } else if (roll <= 48) {
      final shield = eventShieldGain(8 + room);
      gainPlayerShield(shield);
      textIt = 'Piano 0 — Piccola corazza rotta.\n+$shield Scudo.';
      textEn = 'Floor 0 — Small broken armor.\n+$shield Shield.';
    } else if (roll <= 70) {
      floorZeroWeakNpcEvent();
    } else if (roll <= 88) {
      gainDungeonExp(18, forceLevelCheck: false);
      textIt = 'Piano 0 — Incisione per principianti.\n+18 EXP.';
      textEn = 'Floor 0 — Beginner engraving.\n+18 EXP.';
    } else {
      spawnFloorZeroEnemy();
    }
  }

  int eventShieldGain(int value) {
    if (equippedTitleIds.contains('principiante')) {
      return max(1, (value / 2).ceil()).toInt();
    }
    return value;
  }

  void floorZeroWeakNpcEvent() {
    const candidateIds = [
      'mela_seedling',
      'lucciola_fredda',
      'rana_di_sale',
      'rana_insalata',
      'gufus_leviante',
    ];

    final pool = _goodNpcs
        .where((npc) => candidateIds.contains(npc.id))
        .where((npc) => !weakNpcRunEncounteredIds.contains(npc.id))
        .where((npc) => !activeAllies.any((ally) => ally.id == npc.id))
        .toList();

    if (pool.isEmpty) {
      final shield = 6 + currentFloor;
      gainPlayerShield(shield);
      textIt =
          'Piano 0 — Nessun altro piccolo NPC risponde.\n'
          'Il dungeon evita di ripetere lo stesso incontro.\n'
          '+$shield Scudo.';
      textEn =
          'Floor 0 — No other small NPC answers.\n'
          'The dungeon avoids repeating the same encounter.\n'
          '+$shield Shield.';
      return;
    }

    final npc = pool[_random.nextInt(pool.length)];
    weakNpcRunEncounteredIds.add(npc.id);
    unlockedNpcIds.add(npc.id);
    final joined = addAllyToParty(npc, replaceIfFull: false);
    prepareSmallNpcActions(npc, forceRefresh: true);

    textIt =
        'Piano 0 — Incontro piccolo.\n\n'
        '${npc.nameIt} ti segue da vicino.\n'
        '${npc.id == 'gufus_leviante' ? 'È impegnato' : 'È fragile'}: combatterà con te per ${smallNpcActions[npc.id] ?? 0} azioni, poi se ne andrà con una sua frase ufficiale.'
        '${npc.id == 'gufus_leviante' ? '\nDi solito è una dolce civetta bianca alta fino al ginocchio, con mantello nero e cappuccio, e un piccolo coltellino. Solo se cede del tutto si apre la Bestia: un’enorme civetta in decadimento con acido alla bocca e occhi bianchi vitrei.' : ''}';
    textEn =
        'Floor 0 — Small encounter.\n\n'
        '${npc.nameEn} follows you closely.\n'
        '${npc.id == 'gufus_leviante' ? 'It is busy' : 'It is fragile'}: it will fight with you for ${smallNpcActions[npc.id] ?? 0} actions, then leave with an official line.'
        '${npc.id == 'gufus_leviante' ? '\nUsually it is a gentle white owl only as tall as your knee, with a black hooded cloak and a small knife. Only if it fully gives in does the Beast open up: a huge decaying owl with acid on its beak and milky white eyes.' : ''}';

    if (!joined) {
      textIt += '\n\nIl party è pieno: resta sbloccato, ma non entra ora.';
      textEn +=
          '\n\nThe party is full: it stays unlocked, but does not join now.';
    }

    _savePermanentProgress();
    saveRunCheckpoint(
      reasonIt: 'NPC piccolo del Piano 0 registrato nel ricordo.',
      reasonEn: 'Small Floor 0 NPC recorded into memory.',
    );
  }

  void spawnFloorZeroEnemy() {
    inCombat = true;
    final enemyHp = 12 + room * 2;
    final enemyAttack = 2 + room ~/ 2;
    enemyParty
      ..clear()
      ..add(
        _EnemyInstance(
          nameIt: 'Occhietto Debole',
          nameEn: 'Weak Little Eye',
          elementId: 'neutral',
          hp: enemyHp,
          maxHp: enemyHp,
          attack: enemyAttack,
          defense: 0,
          boss: false,
          elite: false,
          fetal: false,
          level: 1,
          grade: 0,
          originalPower: enemyPowerScoreFromStats(enemyHp, enemyAttack, 0),
        ),
      );
    syncPrimaryEnemyFromParty();

    if (activeAllies.any((npc) => npc.id == 'gufus_leviante') &&
        !hasRunFlag('gufus_owl_speed_room_$room')) {
      runBoons.add('gufus_owl_speed_room_$room');
      dodgeCharges += 1;
      reactionAvailable = true;
    }

    textIt = 'Piano 0 — Fight piccolo.\n${enemyPartySummary()}';
    textEn = 'Floor 0 — Small fight.\n${enemyPartySummary()}';
  }

  _EnemyTemplate chooseEnemyTemplate({
    required bool boss,
    bool avoidOculians = false,
  }) {
    var pool = _enemies.where((e) => e.boss == boss).toList();
    if (avoidOculians) {
      final filtered = pool.where((e) => !isOculianEnemyTemplate(e)).toList();
      if (filtered.isNotEmpty) pool = filtered;
    }
    if (pool.isEmpty) {
      return _enemies[_random.nextInt(_enemies.length)];
    }

    final preferred = preferredEnemyElementsForSheet();

    // Più la scheda è forte, più il dungeon tende a scegliere elementi che la disturbano.
    final counterChance = (35 + currentFloor * 4 + threat)
        .clamp(35, 82)
        .toInt();
    final counterPool = pool
        .where((e) => preferred.contains(e.elementId))
        .toList();

    if (counterPool.isNotEmpty && _random.nextInt(100) < counterChance) {
      return counterPool[_random.nextInt(counterPool.length)];
    }

    return pool[_random.nextInt(pool.length)];
  }

  bool isOculianEnemyTemplate(_EnemyTemplate template) {
    final nIt = template.nameIt.toLowerCase();
    final nEn = template.nameEn.toLowerCase();
    return template.elementId == 'oculum' ||
        nIt.contains('oculian') ||
        nIt.contains('oculiano') ||
        nIt.contains('cultista') ||
        nEn.contains('oculian') ||
        nEn.contains('cultist');
  }

  void spawnEnemy({bool boss = false, bool elite = false}) {
    clearChoices();
    enemyParty.clear();
    enemyTurnPending = false;
    consecutivePlayerCritsThisFight = 0;

    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    valleyParticipatedInFight = valleyInFight;
    valleyBloomResolvedThisFight = false;

    final multipleChance = boss
        ? 30
        : elite
        ? 20
        : 8 + currentFloor;
    final enemyCount = boss
        ? (_random.nextInt(100) < multipleChance ? 2 + _random.nextInt(2) : 1)
        : (_random.nextInt(100) < multipleChance ? 2 + _random.nextInt(2) : 1);

    for (int i = 0; i < enemyCount; i++) {
      var template = chooseEnemyTemplate(
        boss: boss && i == 0,
        avoidOculians: hasOculianPact,
      );
      final localBoss = boss && i == 0;
      var localElite =
          elite ||
          (!localBoss && currentFloor >= 4 && _random.nextInt(100) < 18);

      final factor = roomDifficultyFactor();
      final procedural = proceduralDifficultyMultiplier;
      final baseRaw =
          8 +
          room * 2 +
          currentFloor * 7 +
          runGrade * 6 +
          threat +
          sheetPowerScore ~/ 30;
      final base = max(6, (baseRaw * factor * procedural).round());

      var nameIt = template.nameIt;
      var nameEn = template.nameEn;

      final baghestFloor = selectedDifficultyId == 'easy'
          ? 8
          : selectedDifficultyId == 'normal'
          ? 9
          : selectedDifficultyId == 'very_easy'
          ? 7
          : 10;
      final forceBaghest =
          localBoss &&
          currentFloor == baghestFloor &&
          !hasBaghestEye &&
          !baghestBossDefeated;

      if (forceBaghest) {
        nameIt = 'Eiva Baghest';
        nameEn = 'Eiva Baghest';
      }

      if (localElite) {
        nameIt = 'Corrotto Rosso — $nameIt';
        nameEn = 'Red Corrupted — $nameEn';
      }

      if (!localBoss && currentFloor >= 6 && _random.nextInt(100) < 18) {
        nameIt = 'Affamato dal Fato — $nameIt';
        nameEn = 'Fate-Starved — $nameEn';
        localElite = true;
      }

      final offensePunish = sheetOffenseScore > sheetDefenseScore ? 1.08 : 1.0;
      final defensePunish = sheetDefenseScore > sheetOffenseScore ? 1.10 : 1.0;
      final magicPunish =
          sheetMagicScore > max(sheetOffenseScore, sheetDefenseScore)
          ? 1.08
          : 1.0;

      var maxHp =
          (base +
                  template.hpMod * 10 +
                  (localBoss
                      ? 95 + currentFloor * 30
                      : localElite
                      ? 36 + currentFloor * 6
                      : 0))
              .round();

      // Se ci sono più creature, ognuna è un po' più fragile ma il turno nemico è più pericoloso.
      if (enemyCount > 1) {
        maxHp = (maxHp * (localBoss ? 0.82 : 0.68)).round();
      }

      maxHp = (maxHp * offensePunish * magicPunish).round();

      final attack = max(
        2,
        (((base / 4.4).round() +
                    template.atkMod +
                    currentFloor +
                    (localBoss
                        ? currentFloor * 3 + 9
                        : localElite
                        ? 5
                        : 0)) *
                defensePunish)
            .round(),
      ).toInt();

      final defense = max(
        0,
        (base / 8.8).round() +
            template.defMod +
            currentFloor ~/ 2 +
            (localBoss
                ? currentFloor + 4
                : localElite
                ? 2
                : 0),
      ).toInt();

      final finalHp = forceBaghest ? (maxHp * 1.35).round() : maxHp;
      final finalAttack = forceBaghest ? attack + currentFloor * 3 : attack;
      final finalDefense = forceBaghest ? defense + 4 : defense;
      final enemyLevel = max(
        1,
        currentFloor +
            runGrade +
            (localBoss
                ? 2
                : localElite
                ? 1
                : 0),
      );
      final enemyGrade = max(
        0,
        runGrade +
            (localBoss
                ? 2
                : localElite
                ? 1
                : 0),
      );

      MonsterBookEntry? matchedMonster;
      for (final m in monsterBookEntries) {
        final mEn = m.nameEn.toLowerCase();
        final mIt = m.nameIt.toLowerCase();
        if (nameEn.toLowerCase().contains(mEn) ||
            nameIt.toLowerCase().contains(mIt) ||
            nameEn.toLowerCase().contains(m.id) ||
            nameIt.toLowerCase().contains(m.id)) {
          matchedMonster = m;
          break;
        }
      }

      enemyParty.add(
        _EnemyInstance(
          nameIt: nameIt,
          nameEn: nameEn,
          elementId: forceBaghest ? 'shadow' : template.elementId,
          hp: finalHp,
          maxHp: finalHp,
          attack: finalAttack,
          defense: finalDefense,
          boss: localBoss,
          elite: localElite,
          fetal: nameIt.contains('Fetale') || nameEn.contains('Fetal'),
          level: enemyLevel,
          grade: enemyGrade,
          originalPower: enemyPowerScoreFromStats(
            finalHp,
            finalAttack,
            finalDefense,
          ),
          monsterId: matchedMonster?.id,
          skillIds: matchedMonster?.skillIds,
          dropIds: matchedMonster?.dropIds,
          spriteAssetPath: matchedMonster?.spriteAssetPath,
        ),
      );
    }

    if (hasOculianPact) {
      final ally = npcById('minor_oculian_watcher');
      if (ally != null) {
        unlockedNpcIds.add(ally.id);
        addAllyToParty(ally, replaceIfFull: true, save: false);
      }
      enemyWeak += 1;
    }

    syncPrimaryEnemyFromParty();
    ensureBossHasUnlockedArtSkill();
    saveRunCheckpoint(
      reasonIt: 'Battaglia registrata nel salvataggio.',
      reasonEn: 'Battle recorded into the save.',
    );

    if (nextEnemyWeakened) {
      nextEnemyWeakened = false;
      enemyWeak += 2;
      for (final enemy in enemyParty) {
        enemy.attack = max(1, enemy.attack - 3).toInt();
      }
      syncPrimaryEnemyFromParty();
    }

    inCombat = true;
    reactionAvailable = true;

    textIt =
        '${boss
            ? 'BOSS DEL PIANO $currentFloor'
            : elite
            ? 'Élite corrotto'
            : 'Fight'}\n\n'
        'Nemici: ${enemyPartySummary()}\n'
        'Scheda letta: $sheetBuildNameIt • Potere $sheetPowerScore\n'
        'Pressione procedurale: ${proceduralDifficultyMultiplier.toStringAsFixed(2)}x\n\n'
        'Turnistica Oculum: tu → alleati → mostri.\n'
        'Puoi usare AoE, buff e Skill Oculum come in un party JRPG, ma sporco di palpebre e Fato.';
    textEn =
        '${boss
            ? 'FLOOR $currentFloor BOSS'
            : elite
            ? 'Corrupted elite'
            : 'Fight'}\n\n'
        'Enemies: ${enemyPartySummary()}\n'
        'Read sheet: $sheetBuildNameEn • Power $sheetPowerScore\n'
        'Procedural pressure: ${proceduralDifficultyMultiplier.toStringAsFixed(2)}x\n\n'
        'Oculum turn order: you → allies → monsters.\n'
        'You can use AoE, buffs and Oculum Skills like a JRPG party, but stained by eyelids and Fate.';

    addLog(
      t(
        'Fight con ${enemyParty.length} creature generato dalla scheda.',
        'Fight with ${enemyParty.length} creatures generated from the sheet.',
      ),
    );
  }

  int elementalIncomingReduction(String elementId) {
    final resist = elementalResist[elementId] ?? 0;
    return resist.clamp(0, 18).toInt();
  }

  void maybeWoundedAllyAssist(_EnemyInstance target) {
    if (!woundedAllyAssistReady) return;

    woundedAllyAssistReady = false;

    if (_random.nextInt(100) >= 15) {
      textIt +=
          '\n\nAlleato salvato: prova ad aiutarti, ma la paura lo blocca.';
      textEn += '\n\nSaved ally: they try to help you, but fear stops them.';
      return;
    }

    const allyCritDamage = 500;
    target.hp = max(0, target.hp - allyCritDamage).toInt();
    completeAchievement('saved_ally_strike');

    textIt +=
        '\n\nAlleato salvato: entra nel primo turno e colpisce con te.'
        '\n+500 danni critici.';
    textEn +=
        '\n\nSaved ally: joins the first turn and strikes with you.'
        '\n+500 critical damage.';
  }

  void smallNpcsFollowPlayerAttack({
    required _EnemyInstance target,
    required bool useVc,
  }) {
    final helpers = activeAllies
        .where(isSmallNpc)
        .where((npc) => (smallNpcActions[npc.id] ?? 0) > 0)
        .toList();

    if (helpers.isEmpty || target.hp <= 0) return;

    final linesIt = <String>[];
    final linesEn = <String>[];

    for (final npc in helpers) {
      if (target.hp <= 0) break;

      var damage = 1 + currentFloor ~/ 3;
      var extraIt = '';
      var extraEn = '';

      switch (npc.id) {
        case 'affogato_temporaneo':
        case 'affogato_temporaneo_2':
        case 'affogato_temporaneo_3':
        case 'affogato_temporaneo_4':
          damage = 2 + currentFloor ~/ 2 + totalOculum ~/ 4;
          if (chance(18)) enemyWeak += 1;
          extraIt = ' acqua morta';
          extraEn = ' dead water';
          break;

        case 'gufus_leviante':
          damage = 2 + currentFloor ~/ 2;
          if (chance(15)) enemyBleed += 1;
          extraIt = ' coltellino e piuma';
          extraEn = ' knife and feather';
          break;

        case 'rana_insalata':
          damage = 1 + currentFloor ~/ 4;
          if (chance(16)) {
            playerHp = min(playerMaxHp, playerHp + 2);
            extraIt = ' e +2 HP';
            extraEn = ' and +2 HP';
          }
          break;

        case 'rana_di_sale':
          damage = 1 + currentFloor ~/ 4;
          if (chance(18)) gainPlayerShield(2);
          extraIt = ' sale e scudo';
          extraEn = ' salt and shield';
          break;

        case 'lucciola_fredda':
          damage = 1 + currentFloor ~/ 4;
          if (chance(18)) runCritBonus += 1;
          extraIt = ' luce fredda';
          extraEn = ' cold light';
          break;

        case 'mela_seedling':
          damage = 1 + currentFloor ~/ 4;
          if (chance(18)) playerHp = min(playerMaxHp, playerHp + 2);
          extraIt = ' radice tenera';
          extraEn = ' tender root';
          break;

        case 'kooba_glimmer_moralist':
          damage = 1 + currentFloor ~/ 4;
          if (chance(16)) sparklingGears += 1;
          extraIt = ' morale scintillante';
          extraEn = ' glimmering morals';
          break;

        default:
          damage = 1 + currentFloor ~/ 4;
          break;
      }

      // CM gives helpers a slightly cleaner opening, but never makes the chip damage huge.
      if (!useVc && chance(25)) damage += 1;

      target.hp = max(0, target.hp - damage).toInt();

      linesIt.add('${npc.nameIt}: +$damage danni$extraIt');
      linesEn.add('${npc.nameEn}: +$damage damage$extraEn');
    }

    syncPrimaryEnemyFromParty();

    if (linesIt.isNotEmpty) {
      textIt +=
          '\n\nI piccoli compagni seguono il tuo attacco:\n'
          '${linesIt.join('\n')}';
      textEn +=
          '\n\nSmall companions follow your attack:\n'
          '${linesEn.join('\n')}';
    }
  }

  String playerCritFragilityNameIt(int chain) {
    switch (chain.clamp(1, 7)) {
      case 1:
        return 'Fragilità Leggera';
      case 2:
        return 'Fragilità';
      case 3:
        return 'Alta Fragilità';
      case 4:
        return 'Fragilità Estrema';
      case 5:
        return 'Fragilità Distruttiva';
      case 6:
        return 'Fragilità Semi Letale';
      default:
        return 'Fragilità Letale';
    }
  }

  String playerCritFragilityNameEn(int chain) {
    switch (chain.clamp(1, 7)) {
      case 1:
        return 'Light Fragility';
      case 2:
        return 'Fragility';
      case 3:
        return 'High Fragility';
      case 4:
        return 'Extreme Fragility';
      case 5:
        return 'Destructive Fragility';
      case 6:
        return 'Semi-Lethal Fragility';
      default:
        return 'Lethal Fragility';
    }
  }

  void attack({required bool useVc}) {
    if (!canUseCombatInput) return;
    if (playerStunTurns > 0) {
      setState(() {
        playerStunTurns = max(0, playerStunTurns - 1);
        textIt += '\n\nSei stordito: perdi questa azione.';
        textEn += '\n\nYou are stunned: you lose this action.';
        enemyTurn();
      });
      return;
    }

    if (!useVc && !canUseCmAttack()) {
      showLockedTechniqueMessage('Attacco CM', 'CM Attack');
      return;
    }

    if (useVc && posteaGrenadesEquipped) {
      attackAllEnemies(useVc: true);
      return;
    }

    setState(() {
      clearChoices();
      syncPrimaryEnemyFromParty();

      final target = firstAliveEnemy();
      if (target == null) {
        completeCombatVictory();
        return;
      }
      final stat = useVc ? totalVc : totalCm;
      final playerAtkDebuff = playerAttackDebuffTurns > 0
          ? playerAttackDebuffValue
          : 0;
      final critRoll = _random.nextInt(20) + 1;
      final crit = critRoll == 20;
      var damage =
          max(1, totalDamage - playerAtkDebuff) +
          stat ~/ 2 +
          elementalDamageBonus() -
          target.defense ~/ 2;
      final consumedRelicRollBonus = relicNextRollBonus;
      if (consumedRelicRollBonus > 0) {
        damage += consumedRelicRollBonus;
        relicNextRollBonus = 0;
      }

      if (crit) {
        consecutivePlayerCritsThisFight++;
        final fragilityStep = consecutivePlayerCritsThisFight.clamp(1, 7);
        enemyWeak += fragilityStep;
        damage += 5;
        if (fragilityStep >= 7) {
          damage = damage * 5 + 5;
        } else {
          damage = (damage * 1.55).round();
        }
      } else {
        consecutivePlayerCritsThisFight = 0;
      }
      if (runBoons.contains('post_rebirth_lethal') &&
          chance(16 + runCritBonus ~/ 4)) {
        damage = (damage * 5).round();
      }
      if (crit && equippedTitleIds.contains('principiante')) {
        fifiSleepActions = max(fifiSleepActions, 1);
        gainPlayerShield(20);
      }

      if (crit && runBoons.contains('asher_physical_burn')) {
        enemyBurn += 2 + totalOculum ~/ 2;
      }
      damage = max(1, damage + enemyWeak);
      final attackType = useVc ? 'VC' : 'CM';
      damage = damageAfterEnemyAdaptation(target, attackType, damage);

      target.hp = max(0, target.hp - damage).toInt();
      var rifleBurstDamage = 0;
      var unarmedChainDamage = 0;
      var unarmedCritEffectIt = '';
      var unarmedCritEffectEn = '';
      if (starterWeapon?.id == 'postea_auto_rifle' && target.hp > 0) {
        rifleBurstDamage = max(1, 3 + totalVc ~/ 4 - target.defense ~/ 5);
        target.hp = max(0, target.hp - rifleBurstDamage).toInt();
      }
      if (starterWeapon?.id == 'combattimento_mani_nude' && target.hp > 0) {
        unarmedChainDamage = max(
          2,
          5 + combo + totalVc ~/ 5 - target.defense ~/ 6,
        ).toInt();
        target.hp = max(0, target.hp - unarmedChainDamage).toInt();
        if (crit) {
          target.stunTurns = max(target.stunTurns, 1);
          enemyWeak += 2;
          combo += 1;
          unarmedCritEffectIt =
              ' Critico marziale: stordimento, +2 Fragilità, +1 combo.';
          unarmedCritEffectEn =
              ' Martial critical: stun, +2 Fragility, +1 combo.';
        }
      }
      smallNpcsFollowPlayerAttack(target: target, useVc: useVc);
      final adaptationIt = applyBossAdaptation(target, attackType);

      // Effetti elementali applicati direttamente al bersaglio.
      // IMPORTANTE: non riscrivere enemyParty.first.hp = enemyHp [BUG EVITATO],
      // altrimenti in fight multipli il primo nemico può "rinascere"
      // copiando gli HP del secondo.
      applyElementalHitEffects(target);
      applyElementalComboBonus();
      syncPrimaryEnemyFromParty();

      textIt =
          '${useVc ? 'Attacco VC' : 'Attacco CM'}\n'
          'Bersaglio: ${target.nameIt}\n'
          'Elemento: ${elementName(activeElementId)}\n'
          'Danni: $damage${consumedRelicRollBonus > 0 ? ' (+$consumedRelicRollBonus benedizione)' : ''}${crit ? ' CRITICO 20: +5 danni, ${playerCritFragilityNameIt(consecutivePlayerCritsThisFight)}' : ''}.'
          '${rifleBurstDamage > 0 ? '\nFucile Automatico di Postea: raffica +$rifleBurstDamage danni.' : ''}'
          '${unarmedChainDamage > 0 ? '\nCombattimento a Mani Nude: colpo concatenato +$unarmedChainDamage danni.$unarmedCritEffectIt' : ''}'
          '$adaptationIt';
      textEn =
          '${useVc ? 'VC attack' : 'CM attack'}\n'
          'Target: ${target.nameEn}\n'
          'Element: ${elementName(activeElementId)}\n'
          'Damage: $damage${consumedRelicRollBonus > 0 ? ' (+$consumedRelicRollBonus blessing)' : ''}${crit ? ' NATURAL 20 CRITICAL: +5 damage, ${playerCritFragilityNameEn(consecutivePlayerCritsThisFight)}' : ''}.'
          '${rifleBurstDamage > 0 ? '\nPostea Automatic Rifle: burst +$rifleBurstDamage damage.' : ''}'
          '${unarmedChainDamage > 0 ? '\nBare-Hand Combat: chained hit +$unarmedChainDamage damage.$unarmedCritEffectEn' : ''}'
          '${adaptationIt.isEmpty ? '' : '\n${target.boss ? 'Boss adapts to this attack type.' : 'Mini-boss adapts to this attack.'}'}';

      if (runLifesteal > 0) {
        final heal = min(12, runLifesteal + damage ~/ 8);
        playerHp = min(playerMaxHp, playerHp + heal);
      }

      maybeWoundedAllyAssist(target);

      defeatDeadEnemiesFromParty();

      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }

      syncPrimaryEnemyFromParty();
      alliesAct();

      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }

      enemyTurn();
    });
  }

  String applyBossAdaptation(_EnemyInstance target, String attackType) {
    if (target.hp <= 0) return '';
    final key = target.boss ? bossAttackFamily(attackType) : attackType;
    if (target.adaptedAttackTypes.contains(key)) return '';
    target.adaptedAttackTypes.add(key);

    if (target.boss) {
      final gain = 2 + currentFloor ~/ 4;
      target.defense += gain;
      target.attack += 1;
      return '\nBoss: si adatta alla tipologia $key (+$gain Difesa, resistenza alta).';
    }
    if (target.elite) {
      final gain = 1 + currentFloor ~/ 6;
      target.defense += gain;
      return '\nMini-Boss: si adatta al colpo $attackType (+$gain Difesa, resistenza).';
    }
    return '';
  }

  String bossAttackFamily(String attackType) {
    if (attackType.contains('CM')) return 'CM';
    if (attackType.contains('VC')) return 'VC';
    if (attackType.toLowerCase().contains('reliquia')) return 'Reliquia';
    if (attackType.toLowerCase().contains('art')) return 'Art';
    return attackType;
  }

  int damageAfterEnemyAdaptation(
    _EnemyInstance target,
    String attackType,
    int rawDamage,
  ) {
    final key = target.boss ? bossAttackFamily(attackType) : attackType;
    if (!target.adaptedAttackTypes.contains(key)) return max(1, rawDamage);

    final multiplier = target.boss ? 0.55 : 0.75;
    return max(1, (rawDamage * multiplier).round()).toInt();
  }

  void applyElementalHitEffects(_EnemyInstance target) {
    switch (activeElementId) {
      case 'fire':
        enemyBurn += 2 + totalOculum ~/ 2;
        target.burnTurns = max(target.burnTurns, 2);
        target.burnPotency = max(target.burnPotency, 2 + totalOculum ~/ 2);
        break;
      case 'water':
        playerHp = min(playerMaxHp, playerHp + 3 + totalOculum ~/ 2);
        break;
      case 'wind':
        if (chance(30)) dodgeCharges++;
        combo++;
        break;
      case 'earth':
        gainPlayerShield(5 + willMateriaDefense ~/ 2);
        break;
      case 'lightning':
        if (chance(30)) {
          target.hp = max(0, target.hp - (5 + totalOculum)).toInt();
        }
        break;
      case 'ice':
        enemyWeak += 2;
        target.attack = max(1, target.attack - 1).toInt();
        target.slowTurns = max(target.slowTurns, 1);
        target.attackDebuffTurns = max(target.attackDebuffTurns, 1);
        target.attackDebuffValue = max(target.attackDebuffValue, 1);
        break;
      case 'sound':
        enemyWeak++;
        runCritBonus += 1;
        break;
      case 'poison':
        enemyBleed += 2;
        break;
      case 'ash':
        enemyBurn++;
        gainPlayerShield(4);
        break;
      case 'blood':
        enemyBleed += 1;
        playerHp = min(playerMaxHp, playerHp + 2 + runLifesteal);
        break;
      case 'crystal':
        gainPlayerShield(3 + totalDefense ~/ 8);
        break;
      case 'shadow':
        playerHp = min(playerMaxHp, playerHp + 2 + totalOculum ~/ 2);
        break;
    }
  }

  int absorbWithSummons(
    int incoming,
    List<String> reportIt,
    List<String> reportEn, {
    bool criticalHit = false,
  }) {
    var remaining = incoming;

    if (pawnHp > 0 && remaining > 0) {
      pawnShield += 10;
      final dodgeChance = clampPercent(7 + pawnVolonta ~/ 2);
      if (chance(dodgeChance)) {
        reportIt.add(
          'Pawn si mette davanti a te, schiva il colpo e prende +10 Scudo.',
        );
        reportEn.add(
          'Pawn steps in front of you, dodges the hit and gains +10 Shield.',
        );
        return 0;
      }

      final beforePawnHp = pawnHp;
      final beforePawnShield = pawnShield;

      final shieldAbsorb = min(pawnShield, remaining);
      pawnShield -= shieldAbsorb;
      remaining -= shieldAbsorb;

      final hpAbsorb = min(pawnHp, remaining);
      pawnHp -= hpAbsorb;
      remaining -= hpAbsorb;

      final absorbed = shieldAbsorb + hpAbsorb;

      if (beforePawnHp > 0 && pawnHp <= 0) {
        reportIt.add(
          'Pawn prende il colpo al posto tuo e muore. '
          'Ha assorbito $absorbed danni ($shieldAbsorb Scudo, $hpAbsorb HP).',
        );
        reportEn.add(
          'Pawn takes the hit instead of you and dies. '
          'It absorbed $absorbed damage ($shieldAbsorb Shield, $hpAbsorb HP).',
        );
        addLog(t('Pawn è morto proteggendoti.', 'Pawn died protecting you.'));
      } else {
        reportIt.add(
          'Pawn prende il colpo al posto tuo: assorbe $absorbed danni. '
          'HP $pawnHp/$pawnMaxHp, Scudo $pawnShield/$beforePawnShield.',
        );
        reportEn.add(
          'Pawn takes the hit instead of you: absorbs $absorbed damage. '
          'HP $pawnHp/$pawnMaxHp, Shield $pawnShield/$beforePawnShield.',
        );
      }
    }

    if (cipoSerpentHp > 0 && remaining > 0) {
      final before = cipoSerpentHp;
      final absorbed = min(cipoSerpentHp, remaining);
      cipoSerpentHp -= absorbed;
      remaining -= absorbed;

      if (before > 0 && cipoSerpentHp <= 0) {
        reportIt.add(
          'Il serpente di Cipo sibila, attira il colpo e si spezza in legno verde. Assorbe $absorbed danni.',
        );
        reportEn.add(
          'Cipo serpent hisses, draws the hit and breaks into green wood. It absorbs $absorbed damage.',
        );
      } else {
        reportIt.add(
          'Il serpente di Cipo attira il colpo: $absorbed danni assorbiti. HP $cipoSerpentHp/$cipoSerpentMaxHp.',
        );
        reportEn.add(
          'Cipo serpent draws the hit: $absorbed damage absorbed. HP $cipoSerpentHp/$cipoSerpentMaxHp.',
        );
      }
    }

    if (posteaEliteGuardInParty && posteaEliteGuardHp > 0 && remaining > 0) {
      posteaEliteGuardShield += 8 + currentFloor;
      if (posteaEliteGuardCriticalShieldActive) {
        final beforeCriticalShield = remaining;
        remaining = max(1, (remaining / 2).ceil());

        if (criticalHit) {
          posteaEliteGuardCriticalShieldActive = false;
          completeAchievement('critical_shield_broken');
        }

        reportIt.add(
          criticalHit
              ? 'Scudo Critico della Guardia Élite: divide $beforeCriticalShield → $remaining, poi si spezza sul critico.'
              : 'Scudo Critico della Guardia Élite: divide $beforeCriticalShield → $remaining.',
        );
        reportEn.add(
          criticalHit
              ? 'Elite Guard Critical Shield: divides $beforeCriticalShield → $remaining, then breaks on the critical hit.'
              : 'Elite Guard Critical Shield: divides $beforeCriticalShield → $remaining.',
        );
      }

      final criticalShield =
          !criticalHit && posteaEliteGuardShield > 0 && chance(18);

      if (criticalShield) {
        final reflected = max(1, remaining ~/ 3);
        final target = firstAliveEnemy();
        if (target != null) {
          target.hp = max(0, target.hp - reflected).toInt();
        }
        reportIt.add(
          'Armatura Élite Postea: Scudo Critico. La guardia annulla il colpo e riflette $reflected danni.',
        );
        reportEn.add(
          'Postea Elite Armor: Critical Shield. The guard cancels the hit and reflects $reflected damage.',
        );
        defeatDeadEnemiesFromParty();
        return 0;
      }

      final beforeGuardHp = posteaEliteGuardHp;
      final beforeGuardShield = posteaEliteGuardShield;
      final shieldAbsorb = min(posteaEliteGuardShield, remaining);
      posteaEliteGuardShield -= shieldAbsorb;
      remaining -= shieldAbsorb;

      final hpAbsorb = min(posteaEliteGuardHp, remaining);
      posteaEliteGuardHp -= hpAbsorb;
      remaining -= hpAbsorb;

      final absorbed = shieldAbsorb + hpAbsorb;
      if (beforeGuardHp > 0 && posteaEliteGuardHp <= 0) {
        activeAllies.removeWhere((npc) => npc.id == 'postea_elite_guard');
        clearPosteaEliteGuardState();
        reportIt.add(
          'La Guardia Élite di Postea copre il party col suo set e cade. '
          'Ha assorbito $absorbed danni ($shieldAbsorb Scudo, $hpAbsorb HP).',
        );
        reportEn.add(
          'The Postea Elite Guard covers the party with her set and falls. '
          'She absorbed $absorbed damage ($shieldAbsorb Shield, $hpAbsorb HP).',
        );
        addLog(
          t(
            'La Guardia Élite di Postea è caduta proteggendoti.',
            'The Postea Elite Guard fell while protecting you.',
          ),
        );
      } else {
        reportIt.add(
          'La Guardia Élite di Postea intercetta il colpo: $absorbed danni assorbiti. '
          'HP $posteaEliteGuardHp/$posteaEliteGuardMaxHp, Scudo $posteaEliteGuardShield/$beforeGuardShield.',
        );
        reportEn.add(
          'The Postea Elite Guard intercepts the hit: $absorbed damage absorbed. '
          'HP $posteaEliteGuardHp/$posteaEliteGuardMaxHp, Shield $posteaEliteGuardShield/$beforeGuardShield.',
        );
      }
    }

    if (egoShieldHp > 0 && remaining > 0) {
      final before = egoShieldHp;
      final absorbed = min(egoShieldHp, remaining);
      egoShieldHp -= absorbed;
      remaining -= absorbed;
      reportIt.add(
        before > absorbed
            ? "Scudo dell'Io assorbe $absorbed danni. HP $egoShieldHp."
            : "Scudo dell'Io assorbe $absorbed danni e si infrange.",
      );
      reportEn.add(
        before > absorbed
            ? 'Shield of the Self absorbs $absorbed damage. HP $egoShieldHp.'
            : 'Shield of the Self absorbs $absorbed damage and breaks.',
      );
    }

    if (floralGuardCharges > 0 && remaining > 0) {
      floralGuardCharges--;
      reportIt.add(
        'Un umano floreale si pietrifica davanti al colpo e lo annulla. Guardie rimaste: $floralGuardCharges.',
      );
      reportEn.add(
        'A floral human petrifies before the hit and cancels it. Guards left: $floralGuardCharges.',
      );
      return 0;
    }

    if (skeletonHandsHp > 0 && remaining > 0) {
      final beforeHandsHp = skeletonHandsHp;
      final absorbed = min(skeletonHandsHp, remaining);
      skeletonHandsHp -= absorbed;
      remaining -= absorbed;

      if (beforeHandsHp > 0 && skeletonHandsHp <= 0) {
        reportIt.add(
          'Le Mani del Teschio prendono il colpo al posto tuo e si spezzano. '
          'Assorbono $absorbed danni.',
        );
        reportEn.add(
          'The Skull Hands take the hit instead of you and shatter. '
          'They absorb $absorbed damage.',
        );
        addLog(
          t(
            'Le Mani del Teschio si sono spezzate proteggendoti.',
            'The Skull Hands shattered protecting you.',
          ),
        );
      } else {
        reportIt.add(
          'Le Mani del Teschio prendono il colpo al posto tuo: $absorbed danni assorbiti. '
          'HP $skeletonHandsHp/$skeletonHandsMaxHp.',
        );
        reportEn.add(
          'The Skull Hands take the hit instead of you: $absorbed damage absorbed. '
          'HP $skeletonHandsHp/$skeletonHandsMaxHp.',
        );
      }
    }

    return remaining;
  }

  List<String> enemySkillPoolFor(_EnemyInstance attacker) {
    final pool = <String>{...attacker.skillIds};
    final lowerName = '${attacker.nameIt} ${attacker.nameEn}'.toLowerCase();

    pool.add('generic_power_strike');
    pool.add('generic_guard');
    if (attacker.hp < attacker.maxHp * 0.55 ||
        attacker.elementId == 'water' ||
        attacker.elementId == 'flora' ||
        attacker.elementId == 'dream' ||
        lowerName.contains('slime')) {
      pool.add('generic_heal');
    }
    if (attacker.boss || attacker.elite) {
      pool.add('generic_element_burst');
      pool.add('generic_guard');
    }
    if (attacker.elementId == 'blood' ||
        lowerName.contains('sangue') ||
        lowerName.contains('headless') ||
        lowerName.contains('senza testa')) {
      pool.add('generic_blood_rite');
    }
    if (attacker.elementId == 'shadow' ||
        attacker.elementId == 'nullum' ||
        attacker.elementId == 'oculum' ||
        attacker.elementId == 'psyche') {
      pool.add('generic_dark_hex');
    }
    if (attacker.elementId == 'oculum') {
      pool.add('generic_oculum_guard');
    }

    return pool.toList();
  }

  bool tryExecuteEnemySkill(
    _EnemyInstance attacker,
    String skillId,
    List<String> reportIt,
    List<String> reportEn,
  ) {
    switch (skillId) {
      case 'generic_power_strike':
        {
          var dmg = attacker.attack + currentFloor + attacker.level ~/ 2;
          if (attacker.elite) dmg += 4;
          if (attacker.boss) dmg += 8 + currentFloor;
          dmg = max(1, dmg - elementalIncomingReduction(attacker.elementId));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          reportIt.add(
            '${attacker.nameIt} usa Assalto ${elementName(attacker.elementId)}: -$applied HP.',
          );
          reportEn.add(
            '${attacker.nameEn} uses ${elementName(attacker.elementId)} Assault: -$applied HP.',
          );
          return true;
        }

      case 'generic_guard':
        {
          final guard = 3 + currentFloor ~/ 2 + (attacker.elite ? 2 : 0);
          attacker.defense += guard;
          attacker.attackDebuffTurns = max(0, attacker.attackDebuffTurns - 1);
          reportIt.add(
            '${attacker.nameIt} si mette in guardia: +$guard Difesa.',
          );
          reportEn.add(
            '${attacker.nameEn} takes guard stance: +$guard Defense.',
          );
          return true;
        }

      case 'generic_heal':
        {
          final heal = max(
            4,
            attacker.maxHp ~/ (attacker.boss ? 6 : 8) + currentFloor,
          );
          final before = attacker.hp;
          attacker.hp = min(attacker.maxHp, attacker.hp + heal).toInt();
          reportIt.add(
            '${attacker.nameIt} si cura: +${attacker.hp - before} HP.',
          );
          reportEn.add(
            '${attacker.nameEn} heals: +${attacker.hp - before} HP.',
          );
          return attacker.hp > before;
        }

      case 'generic_element_burst':
        {
          var dmg = attacker.attack + 8 + currentFloor * 2;
          if (attacker.boss) dmg += 10;
          dmg = max(1, dmg - elementalIncomingReduction(attacker.elementId));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          playerSlowTurns = max(playerSlowTurns, 1);
          reportIt.add(
            '${attacker.nameIt} apre una Skill d area ${elementName(attacker.elementId)}: -$applied HP e Slow.',
          );
          reportEn.add(
            '${attacker.nameEn} opens an area ${elementName(attacker.elementId)} Skill: -$applied HP and Slow.',
          );
          return true;
        }

      case 'generic_blood_rite':
        {
          final selfCost = min(attacker.hp - 1, max(1, currentFloor));
          if (selfCost > 0) attacker.hp -= selfCost;
          var dmg = attacker.attack + 6 + selfCost * 2;
          dmg = max(1, dmg - elementalIncomingReduction('blood'));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          playerBleedTurns = max(playerBleedTurns, 2);
          reportIt.add(
            '${attacker.nameIt} usa Rito di Sangue: perde $selfCost HP, tu subisci -$applied HP e Sanguinamento.',
          );
          reportEn.add(
            '${attacker.nameEn} uses Blood Rite: it loses $selfCost HP, you take -$applied HP and Bleed.',
          );
          return true;
        }

      case 'generic_dark_hex':
        {
          playerDefenseDebuffTurns = max(playerDefenseDebuffTurns, 2);
          playerDefenseDebuffValue = max(
            playerDefenseDebuffValue,
            2 + attacker.grade,
          );
          playerAttackDebuffTurns = max(playerAttackDebuffTurns, 1);
          playerAttackDebuffValue = max(playerAttackDebuffValue, 1);
          reportIt.add(
            '${attacker.nameIt} sussurra una Maledizione Oscura: attacco e difesa ridotti.',
          );
          reportEn.add(
            '${attacker.nameEn} whispers a Dark Hex: attack and defense reduced.',
          );
          return true;
        }

      case 'generic_oculum_guard':
        {
          final guard = 5 + attacker.grade * 2 + currentFloor ~/ 2;
          attacker.defense += guard;
          attacker.hp = min(attacker.maxHp, attacker.hp + guard).toInt();
          reportIt.add(
            '${attacker.nameIt} chiude la palpebra dell Oculum: +$guard Difesa e recupero.',
          );
          reportEn.add(
            '${attacker.nameEn} closes the Oculum eyelid: +$guard Defense and recovery.',
          );
          return true;
        }

      case 'postea_coordinated_strike':
        {
          final soldiersAlive = enemyParty
              .where(
                (enemy) => enemy.hp > 0 && enemy.monsterId == 'postea_soldier',
              )
              .length;
          var dmg = attacker.attack + (soldiersAlive > 1 ? 6 : 0);
          dmg = max(1, dmg - elementalIncomingReduction(attacker.elementId));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          reportIt.add(
            '${attacker.nameIt} usa Colpo Coordinato: -$applied HP'
            '${soldiersAlive > 1 ? ' (+bonus squadra)' : ''}.',
          );
          reportEn.add(
            '${attacker.nameEn} uses Coordinated Strike: -$applied HP'
            '${soldiersAlive > 1 ? ' (+squad bonus)' : ''}.',
          );
          return true;
        }

      case 'postea_defensive_stance':
        {
          attacker.defense += 6;
          attacker.hp = min(attacker.maxHp, attacker.hp + 10);
          reportIt.add(
            '${attacker.nameIt} assume Postura Difensiva: +6 Difesa e stabilizza l armatura.',
          );
          reportEn.add(
            '${attacker.nameEn} takes Defensive Stance: +6 Defense and stabilizes armor.',
          );
          return true;
        }

      case 'postea_grenade':
        {
          attacker.skillIds.remove('postea_grenade');
          var dmg = 1 + _random.nextInt(100) + attacker.attack;
          dmg = max(1, dmg - elementalIncomingReduction(attacker.elementId));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          playerBurnTurns = max(playerBurnTurns, 1);
          reportIt.add(
            'Il Soldato Elite stacca una granata dal cinturone. Il Fato smette di respirare.',
          );
          reportIt.add('Granata di Postea: -$applied HP.');
          reportEn.add(
            'The Elite Soldier pulls a grenade from its belt. Fate stops breathing.',
          );
          reportEn.add('Postea Grenade: -$applied HP.');
          return true;
        }

      case 'postea_breach_blade':
        {
          var dmg = attacker.attack + 25 + currentFloor;
          dmg = max(1, dmg - elementalIncomingReduction(attacker.elementId));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          reportIt.add('${attacker.nameIt} usa Lama da Breccia: -$applied HP.');
          reportEn.add('${attacker.nameEn} uses Breach Blade: -$applied HP.');
          return true;
        }

      case 'postea_gene_leviante':
        {
          attacker.defense += 10;
          if (chance(35)) {
            playerAttackDebuffTurns = max(playerAttackDebuffTurns, 1);
            playerAttackDebuffValue = max(playerAttackDebuffValue, 3);
          }
          reportIt.add(
            '${attacker.nameIt} attiva Gene Leviante: il corpo evita parte del futuro.',
          );
          reportEn.add(
            '${attacker.nameEn} activates Leviante Gene: its body avoids part of the future.',
          );
          return true;
        }

      case 'postea_levitation_field':
        {
          var dmg = attacker.attack + 16 + currentFloor * 2;
          dmg = max(1, dmg - elementalIncomingReduction(attacker.elementId));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          playerSlowTurns = max(playerSlowTurns, 2);
          if (chance(25)) playerStunTurns = max(playerStunTurns, 1);
          reportIt.add(
            '${attacker.nameIt} usa Campo di Levitazione Forzata: -$applied HP, rallentamento.',
          );
          reportEn.add(
            '${attacker.nameEn} uses Forced Levitation Field: -$applied HP, slowed.',
          );
          return true;
        }

      case 'postea_vivisection_future':
        {
          final enhanced = posteaScientistEnhanced ? 26 : 0;
          var dmg = attacker.attack + 18 + enhanced + currentFloor * 2;
          dmg = max(1, dmg - elementalIncomingReduction(attacker.elementId));
          final hit = applyPlayerDamage(dmg);
          final applied = hit['hp'] ?? 0;
          playerDefenseDebuffTurns = max(playerDefenseDebuffTurns, 2);
          playerDefenseDebuffValue = max(playerDefenseDebuffValue, 3);
          reportIt.add(
            '${attacker.nameIt} usa Vivisezione del Futuro: -$applied HP e difesa ridotta.',
          );
          reportEn.add(
            '${attacker.nameEn} uses Future Vivisection: -$applied HP and reduced defense.',
          );
          return true;
        }

      case 'bone_crown_rend':
        final base = attacker.attack + 6 + currentFloor ~/ 2;
        final reduction = elementalIncomingReduction(attacker.elementId);
        var dmg = max(1, base - reduction);
        final hit = applyPlayerDamage(dmg);
        dmg = hit['hp'] ?? 0;
        attacker.defense = max(0, attacker.defense - 1);
        reportIt.add(
          '${attacker.nameIt} usa Lacerazione della Corona: -$dmg HP.',
        );
        reportEn.add('${attacker.nameEn} uses Crown Rend: -$dmg HP.');
        return true;
      case 'bone_shield':
        attacker.defense += 6;
        reportIt.add('${attacker.nameIt} evoca un Guscio d\'Ossa (+6 Difesa).');
        reportEn.add('${attacker.nameEn} summons a Bone Shield (+6 Defense).');
        return true;
      case 'embrace_deform':
        final dmg = 6 + currentFloor ~/ 2;
        final hit = applyPlayerDamage(dmg);
        final applied = hit['hp'] ?? 0;
        playerSlowTurns = max(playerSlowTurns, 2);
        playerBleedTurns = max(playerBleedTurns, 1);
        reportIt.add(
          '${attacker.nameIt} usa Abbraccio Deforme: -$applied HP e lenta corruzione.',
        );
        reportEn.add(
          '${attacker.nameEn} uses Deformed Embrace: -$applied HP and slow corruption.',
        );
        return true;
      case 'weep_of_fate':
        runDamageBonus = max(-10, runDamageBonus - 2);
        playerAttackDebuffTurns = max(playerAttackDebuffTurns, 2);
        playerAttackDebuffValue = max(playerAttackDebuffValue, 2);
        reportIt.add(
          '${attacker.nameIt} evoca il Lamento del Fato: il tuo danno cala.',
        );
        reportEn.add(
          '${attacker.nameEn} evokes Weep of Fate: your damage is lowered.',
        );
        return true;
      case 'neck_seal':
        playerShield = max(0, playerShield - 3);
        if (chance(30)) {
          playerStunTurns = max(playerStunTurns, 1);
        }
        reportIt.add(
          '${attacker.nameIt} applica il Sigillo del Collo: -3 Scudo.',
        );
        reportEn.add('${attacker.nameEn} applies Neck Seal: -3 Shield.');
        return true;
      case 'bloody_swarm':
        final hits = 3;
        var total = 0;
        for (int i = 0; i < hits; i++) {
          final part = max(1, (attacker.attack ~/ 2) + (i + 1));
          final hit = applyPlayerDamage(part);
          final applied = hit['hp'] ?? 0;
          total += applied;
          if (playerHp <= 0) break;
        }
        playerBleedTurns = max(playerBleedTurns, 2);
        reportIt.add(
          '${attacker.nameIt} scatena uno Sciame Insanguinato: -$total HP totali.',
        );
        reportEn.add(
          '${attacker.nameEn} unleashes Bloody Swarm: -$total total HP.',
        );
        return true;
      case 'oculum_gaze':
        playerDefenseDebuffTurns = max(playerDefenseDebuffTurns, 2);
        playerDefenseDebuffValue = max(playerDefenseDebuffValue, 3);
        playerBurnTurns = max(playerBurnTurns, 2);
        reportIt.add(
          '${attacker.nameIt} usa Sguardo Marcio: difesa ridotta e bruciatura corrotta.',
        );
        reportEn.add(
          '${attacker.nameEn} uses Rotting Gaze: reduced defense and corruptive burn.',
        );
        return true;
      case 'fate_pressure':
        playerSlowTurns = max(playerSlowTurns, 2);
        playerAttackDebuffTurns = max(playerAttackDebuffTurns, 2);
        playerAttackDebuffValue = max(playerAttackDebuffValue, 2);
        if (chance(25)) {
          playerStunTurns = max(playerStunTurns, 1);
        }
        reportIt.add(
          '${attacker.nameIt} applica Pressione Corrotta: rallentato e indebolito.',
        );
        reportEn.add(
          '${attacker.nameEn} applies Corrupted Pressure: slowed and weakened.',
        );
        return true;
      default:
        return false;
    }
  }

  void enemyTurn() {
    if (!inCombat || gameOver || enemyTurnPending) return;

    enemyTurnPending = true;
    reactionAvailable = false;
    textIt +=
        '\n\nTurno dei mostri in arrivo... CM automatica pronta tra 3 secondi.';
    textEn +=
        '\n\nMonster turn incoming... automatic CM defense ready in 3 seconds.';

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        enemyTurnPending = false;
        _resolveEnemyTurn();
        if (inCombat && !gameOver) {
          reactionAvailable = true;
        }
      });
    });
  }

  void _resolveEnemyTurn() {
    if (!inCombat || gameOver) return;

    final attackers = enemyParty.where((enemy) => enemy.hp > 0).toList();
    if (attackers.isEmpty) {
      completeCombatVictory();
      return;
    }

    final reportIt = <String>[];
    final reportEn = <String>[];

    if (fifiSleepActions > 0) {
      fifiSleepActions--;
      textIt +=
          '\n\nI nemici dormono. Azioni sonno rimaste: $fifiSleepActions.';
      textEn += '\n\nEnemies sleep. Sleep actions left: $fifiSleepActions.';
      return;
    }

    if (playerBurnTurns > 0) {
      final burnDamage = max(1, 3 + currentFloor ~/ 3);
      final hit = applyPlayerDamage(burnDamage);
      final applied = hit['hp'] ?? 0;
      playerBurnTurns = max(0, playerBurnTurns - 1);
      reportIt.add('Bruciatura: -$applied HP.');
      reportEn.add('Burn: -$applied HP.');
    }
    if (playerBleedTurns > 0) {
      final bleedDamage = max(1, 2 + currentFloor ~/ 4);
      playerHp = max(0, playerHp - bleedDamage).toInt();
      playerBleedTurns = max(0, playerBleedTurns - 1);
      reportIt.add('Sanguinamento: -$bleedDamage HP.');
      reportEn.add('Bleeding: -$bleedDamage HP.');
    }

    tickPosteaScientistEnhancement(reportIt, reportEn);

    for (final attacker in attackers) {
      if (attacker.stunTurns > 0) {
        attacker.stunTurns = max(0, attacker.stunTurns - 1);
        reportIt.add('${attacker.nameIt} è stordito e salta il turno.');
        reportEn.add('${attacker.nameEn} is stunned and skips the turn.');
        continue;
      }

      if (tryEnemyKillsSmallNpc(attacker, reportIt, reportEn)) {
        continue;
      }

      if (tryEnemyTargetsValley(attacker, reportIt, reportEn)) {
        continue;
      }

      // Enemy may use a skill instead of a basic attack.
      final skillPool = enemySkillPoolFor(attacker);
      final skillChance =
          24 + (attacker.elite ? 8 : 0) + (attacker.boss ? 12 : 0);
      if (skillPool.isNotEmpty && _random.nextInt(100) < skillChance) {
        final sid = skillPool[_random.nextInt(skillPool.length)];
        if (tryExecuteEnemySkill(attacker, sid, reportIt, reportEn)) {
          if (playerHp <= 0) break;
          continue;
        }
      }

      final attackerDebuff = attacker.attackDebuffTurns > 0
          ? attacker.attackDebuffValue
          : 0;
      final attackerSlowPenalty = attacker.slowTurns > 0 ? 2 : 0;
      final effectiveAttack = max(
        1,
        attacker.attack - attackerDebuff - attackerSlowPenalty,
      );
      final defensePenalty = playerDefenseDebuffTurns > 0
          ? playerDefenseDebuffValue
          : 0;
      final currentDefense = max(0, totalDefense - defensePenalty);
      int incoming =
          effectiveAttack +
          currentFloor * 2 +
          threat ~/ 3 +
          (sheetPowerScore ~/ 130) -
          currentDefense ~/ 3;
      incoming = max(1, incoming);

      final cmRoll = _random.nextInt(20) + 1;
      final cmTotal = cmRoll + totalCm;
      final cmReduction = max(
        0,
        (cmTotal - 10) ~/ (attacker.boss ? 5 : 4),
      ).toInt();
      if (cmReduction > 0) {
        incoming = max(1, incoming - cmReduction);
      }
      reportIt.add(
        'Difesa automatica CM: 1d20($cmRoll)+CM $totalCm = $cmTotal, -$cmReduction danni.',
      );
      reportEn.add(
        'Automatic CM defense: 1d20($cmRoll)+CM $totalCm = $cmTotal, -$cmReduction damage.',
      );

      final reduction = elementalIncomingReduction(attacker.elementId);
      incoming = max(1, incoming - reduction);

      if (sheetDefenseScore > sheetOffenseScore + 35 &&
          _random.nextInt(100) < 10 + currentFloor) {
        incoming += 1 + currentFloor ~/ 3;
      }

      final enemyCrit = _random.nextInt(20) + 1 == 20;
      if (enemyCrit) {
        incoming = (incoming * 1.65).round();
      }

      var playerCriticalShieldApplied = false;
      if (criticalShieldActive && !posteaEliteGuardInParty) {
        final beforeCriticalShield = incoming;
        incoming = max(1, (incoming / 2).ceil());
        criticalShieldBlocks++;
        playerCriticalShieldApplied = true;

        if (enemyCrit) {
          criticalShieldActive = false;
          if (criticalShieldBlocks > 0) {
            completeAchievement('critical_shield_broken');
          }
        }

        reportIt.add(
          enemyCrit
              ? 'Scudo Critico: divide $beforeCriticalShield → $incoming, poi si spezza sul critico.'
              : 'Scudo Critico: divide $beforeCriticalShield → $incoming.',
        );
        reportEn.add(
          enemyCrit
              ? 'Critical Shield: divides $beforeCriticalShield → $incoming, then breaks on the critical hit.'
              : 'Critical Shield: divides $beforeCriticalShield → $incoming.',
        );
      }

      final dodgePenalty = playerSlowTurns > 0 ? 8 : 0;
      if (dodgeCharges > 0 &&
          _random.nextInt(100) < max(0, 18 + dodgeCharges * 5 - dodgePenalty)) {
        dodgeCharges--;
        reportIt.add('${attacker.nameIt}: schivato.');
        reportEn.add('${attacker.nameEn}: dodged.');
        continue;
      }

      incoming = absorbWithSummons(
        incoming,
        reportIt,
        reportEn,
        criticalHit: enemyCrit,
      );
      if (incoming <= 0) continue;

      if (criticalShieldActive && !playerCriticalShieldApplied) {
        final beforeCriticalShield = incoming;
        incoming = max(1, (incoming / 2).ceil());
        criticalShieldBlocks++;

        if (enemyCrit) {
          criticalShieldActive = false;
          if (criticalShieldBlocks > 0) {
            completeAchievement('critical_shield_broken');
          }
        }

        reportIt.add(
          enemyCrit
              ? 'Scudo Critico: divide $beforeCriticalShield → $incoming, poi si spezza sul critico.'
              : 'Scudo Critico: divide $beforeCriticalShield → $incoming.',
        );
        reportEn.add(
          enemyCrit
              ? 'Critical Shield: divides $beforeCriticalShield → $incoming, then breaks on the critical hit.'
              : 'Critical Shield: divides $beforeCriticalShield → $incoming.',
        );
      }

      final originalIncoming = incoming;
      final hit = applyPlayerDamage(incoming);
      final oculumShieldAbsorb = hit['oculumShield'] ?? 0;
      final shieldAbsorb = hit['shield'] ?? 0;
      incoming = hit['hp'] ?? 0;

      if (incoming > 0) {
        markNullFatelessWound(attacker, incoming);
      }

      reportIt.add(
        '${attacker.nameIt} [${elementName(attacker.elementId)}] → $originalIncoming danni${enemyCrit ? ' CRITICO' : ''} ($oculumShieldAbsorb Scudo Oculum, $shieldAbsorb Scudo, -$reduction resistenza).',
      );
      reportEn.add(
        '${attacker.nameEn} [${elementName(attacker.elementId)}] → $originalIncoming damage${enemyCrit ? ' CRITICAL' : ''} ($oculumShieldAbsorb Oculum Shield, $shieldAbsorb Shield, -$reduction resistance).',
      );

      if (playerHp <= 0) break;
    }

    if (playerSlowTurns > 0) {
      playerSlowTurns = max(0, playerSlowTurns - 1);
    }
    if (playerAttackDebuffTurns > 0) {
      playerAttackDebuffTurns = max(0, playerAttackDebuffTurns - 1);
    }
    if (playerDefenseDebuffTurns > 0) {
      playerDefenseDebuffTurns = max(0, playerDefenseDebuffTurns - 1);
    }

    // Tick stato per ogni nemico vivo.
    for (final enemy in enemyParty.where((e) => e.hp > 0)) {
      if (enemy.burnTurns > 0) {
        final burnDamage = max(1, enemy.burnPotency);
        enemy.hp = max(0, enemy.hp - burnDamage).toInt();
        enemy.burnTurns = max(0, enemy.burnTurns - 1);
      }
      if (enemy.bleedTurns > 0) {
        final bleedDamage = max(1, enemy.bleedPotency);
        enemy.hp = max(0, enemy.hp - bleedDamage).toInt();
        enemy.bleedTurns = max(0, enemy.bleedTurns - 1);
      }
      if (enemy.slowTurns > 0) enemy.slowTurns = max(0, enemy.slowTurns - 1);
      if (enemy.attackDebuffTurns > 0) {
        enemy.attackDebuffTurns = max(0, enemy.attackDebuffTurns - 1);
      }
      if (enemy.defenseDebuffTurns > 0) {
        enemy.defenseDebuffTurns = max(0, enemy.defenseDebuffTurns - 1);
      }
    }

    // Compatibilità: effetti globali legacy sul primo nemico vivo.
    if (enemyParty.isNotEmpty) {
      final firstAlive = enemyParty.firstWhere(
        (e) => e.hp > 0,
        orElse: () => enemyParty.first,
      );
      if (enemyBurn > 0) {
        firstAlive.burnTurns = max(firstAlive.burnTurns, 2);
        firstAlive.burnPotency = max(
          firstAlive.burnPotency,
          min(enemyBurn, 12 + currentFloor),
        );
        enemyBurn = max(0, enemyBurn - 1).toInt();
      }
      if (enemyBleed > 0) {
        firstAlive.bleedTurns = max(firstAlive.bleedTurns, 2);
        firstAlive.bleedPotency = max(
          firstAlive.bleedPotency,
          min(enemyBleed, 10 + currentFloor),
        );
        enemyBleed = max(0, enemyBleed - 1).toInt();
      }
    }

    defeatDeadEnemiesFromParty();
    syncPrimaryEnemyFromParty();

    textIt += '\n\nTurno dei mostri:\n${reportIt.join('\n')}';
    textEn += '\n\nMonster turn:\n${reportEn.join('\n')}';

    if (enemyParty.isEmpty) {
      completeCombatVictory();
      return;
    }

    if (playerHp <= 0) {
      if (valleyTrainingActive) {
        resolveValleyTrainingDefeat();
        return;
      }
      if (monsterVillageFightActive && resolveMonsterVillageKnockout()) {
        return;
      }
      if (moonSecondChance && !secondChanceUsed) {
        secondChanceUsed = true;
        playerHp = 1;
        textIt += '\n\nLa Seconda Luna ti lascia a 1 HP.';
        textEn += '\n\nThe Second Moon leaves you at 1 HP.';
      } else {
        finishRun(victorious: false);
      }
    }

    if (valleyTrainingActive && inCombat && !gameOver) {
      valleyTrainingTurnsLeft = max(0, valleyTrainingTurnsLeft - 1).toInt();
      if (valleyTrainingTurnsLeft <= 0) {
        resolveValleyTrainingTimeout();
      }
    }
  }

  bool resolveMonsterVillageKnockout() {
    final trueDeathChance = hasMonsterVillageChampionTitle ? 0 : 3;
    if (trueDeathChance > 0 && chance(trueDeathChance)) {
      monsterVillageFightActive = false;
      addLog('Lotta clandestina: il 3% ha morso davvero.');
      finishRun(victorious: false);
      return true;
    }

    final exp = 45 + currentFloor * 14 + defeatedEnemyNamesIt.length * 8;
    final obser = 3 + currentFloor;
    final dust = currentFloor >= 3 ? 1 : 0;
    gainDungeonExp(exp, forceLevelCheck: false);
    obserInRun += obser;
    ascensionDustInRun += dust;
    playerHp = max(1, playerMaxHp ~/ 3).toInt();
    setPlayerShieldAtLeast(8 + currentFloor * 3);
    inCombat = false;
    enemyTurnPending = false;
    monsterVillageFightActive = false;
    fightsSinceTavernRest = 0;
    enemyParty.clear();
    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    syncPrimaryEnemyFromParty();
    clearChoices();

    textIt +=
        '\n\nLotta clandestina: cadi nel cerchio, ma il villaggio ti tira fuori.\n'
        'Morte evitata (${trueDeathChance == 0 ? 'titolo: 0%' : '97%'}).\n'
        '+$exp EXP, +$obser Obser, +$dust Ascension Dust.';
    textEn +=
        '\n\nClandestine fight: you fall inside the ring, but the village pulls you out.\n'
        'Death avoided (${trueDeathChance == 0 ? 'title: 0%' : '97%'}).\n'
        '+$exp EXP, +$obser Obser, +$dust Ascension Dust.';
    addLog('Lotta clandestina conclusa senza morte reale.');
    saveRunCheckpoint(
      reasonIt: 'KO clandestino salvato senza morte reale.',
      reasonEn: 'Clandestine KO saved without true death.',
    );
    return true;
  }

  bool tryEnemyTargetsValley(
    _EnemyInstance attacker,
    List<String> reportIt,
    List<String> reportEn,
  ) {
    if (!valleyInFight || valleyTrainingActive) return false;
    final otherLivingTargets =
        activeAllies.length +
        (pawnHp > 0 ? 1 : 0) +
        (skeletonHandsHp > 0 ? 1 : 0);
    final chanceToHitValley = (38 - otherLivingTargets * 8)
        .clamp(10, 42)
        .toInt();
    if (!chance(chanceToHitValley)) return false;

    var incoming =
        attacker.attack + currentFloor * 2 + threat ~/ 3 - valleyDefense ~/ 3;
    incoming = max(1, incoming).toInt();

    if (valleyBloomGuards > 0 &&
        (incoming >= valleyHp || incoming >= max(10, valleyMaxHp ~/ 3))) {
      valleyBloomGuards--;
      reportIt.add(
        'Lo sbocciato apre le braccia di rami e carne, prendendo il colpo destinato a Valley.',
      );
      reportEn.add(
        'The bloomed creature opens arms of branches and flesh, taking the hit meant for Valley.',
      );
      addLog(
        'Una creatura sbocciata si mette davanti a Valley e viene spezzata al suo posto.',
      );
      return true;
    }

    valleyHp = max(0, valleyHp - incoming).toInt();
    reportIt.add(
      '${attacker.nameIt} colpisce Valley: $incoming danni. Valley $valleyHp/$valleyMaxHp.',
    );
    reportEn.add(
      '${attacker.nameEn} hits Valley: $incoming damage. Valley $valleyHp/$valleyMaxHp.',
    );
    if (valleyHp <= 0) {
      valleyTurnsLeft = 0;
      reportIt.add('Valley viene disperso prima di completare il suo ciclo.');
      reportEn.add('Valley is scattered before completing the cycle.');
    }
    return true;
  }

  void killEnemy() {
    if (enemyParty.isNotEmpty) {
      if (enemyParty.first.hp > 0) {
        enemyParty.first.hp = 0;
      }
      defeatDeadEnemiesFromParty();

      if (enemyParty.isNotEmpty) {
        syncPrimaryEnemyFromParty();
        textIt +=
            '\n\nUna creatura cade, ma il fight continua.\nNemici rimasti: ${enemyPartySummary()}';
        textEn +=
            '\n\nA creature falls, but the fight continues.\nRemaining enemies: ${enemyPartySummary()}';
        return;
      }
    } else if (enemyNameIt.isNotEmpty) {
      defeatedEnemyNamesIt.add(enemyNameIt);
      defeatedEnemyNamesEn.add(enemyNameEn);
    }

    completeCombatVictory();
  }

  void dropUnique() {
    final elementDrops = _uniqueDrops
        .where((drop) => drop.elementId == enemyElementId)
        .toList();
    final pool = elementDrops.isEmpty ? _uniqueDrops : elementDrops;
    final drop = pool[_random.nextInt(pool.length)];
    inventoryDrops.add(drop);
    enemyDropHistoryIt.insert(
      0,
      '• ${drop.nameIt} [${elementName(drop.elementId)}]',
    );
    enemyDropHistoryEn.insert(
      0,
      '• ${drop.nameEn} [${elementName(drop.elementId)}]',
    );
    if (enemyDropHistoryIt.length > 14) enemyDropHistoryIt.removeLast();
    if (enemyDropHistoryEn.length > 14) enemyDropHistoryEn.removeLast();

    if (chance(24)) {
      addQuickPotion('minor', amount: 1);
    }

    progressQuest('drop');

    addLog(
      t(
        'Drop unico ottenuto: ${drop.nameIt}.',
        'Unique drop obtained: ${drop.nameEn}.',
      ),
    );
  }

  void tryUnlockRandomArt() {
    final locked = _allArts
        .where((art) => isArtUnlockableOutsideLateGame(art))
        .where(
          (art) =>
              !art.unlockedByDefault && !unlockedArtIds.contains(art.effectId),
        )
        .toList();
    if (locked.isEmpty) return;
    final art = locked[_random.nextInt(locked.length)];
    unlockedArtIds.add(art.effectId);
    _savePermanentProgress();
    progressQuest('art');
    addLog(
      t(
        'Nuova Art sbloccata: ${art.nameIt}.',
        'New Art unlocked: ${art.nameEn}.',
      ),
    );
  }

  void tryUnlockRandomWeapon() {
    final locked = _starterWeapons
        .where(
          (w) =>
              !w.unlockedByDefault &&
              !unlockedWeaponIds.contains(w.id) &&
              !isStoryLockedWeaponId(w.id),
        )
        .toList();
    if (locked.isEmpty) return;
    final weapon = locked[_random.nextInt(locked.length)];
    unlockedWeaponIds.add(weapon.id);
    _savePermanentProgress();
    addLog(
      t(
        'Nuova arma iniziale sbloccata: ${weapon.nameIt}.',
        'New starting weapon unlocked: ${weapon.nameEn}.',
      ),
    );
  }

  int artSkillOculumCost(String skillId) {
    if (skillId.startsWith('swiftness_martial_art_')) return 0;
    if (skillId.startsWith('modern_school_art_') ||
        skillId.startsWith('kingi_blue_art_') ||
        skillId.startsWith('defiled_postea_art_')) {
      return 0;
    }
    if (skillId.endsWith('autumn_regeneration')) return 0;
    final skill = findArtSkillDef(skillId);
    final lvl = skillLevel(skillId);
    if (skill == null) return 1;
    final base = skill.kind == 'special' ? 2 : 1;
    return (base + (lvl >= 3 ? 1 : 0)).clamp(1, 4).toInt();
  }

  int skillInvestmentMin(String skillId) {
    final lvl = skillLevel(skillId).clamp(1, artSkillMaxLevel(skillId)).toInt();
    if (skillId.endsWith('non_newtonian_liquid')) return 1;
    if (skillId.endsWith('useful_physical_activity')) return 1;
    if (skillId.endsWith('blue_control')) {
      return lvl <= 1
          ? 1
          : lvl == 2
          ? 6
          : 12;
    }
    if (skillId.endsWith('flaming_form')) {
      return lvl <= 1
          ? 5
          : lvl == 2
          ? 8
          : 12;
    }
    if (skillId.endsWith('lightning_form')) {
      return lvl <= 1
          ? 3
          : lvl == 2
          ? 20
          : 30;
    }
    if (skillId.endsWith('runic_guards')) return 1;
    if (skillId.endsWith('fast_upgrade')) {
      if (lvl <= 1) return 1;
      if (lvl == 2) return 4;
      if (lvl == 3) return 6;
      if (lvl == 4) return 8;
      return 10;
    }
    if (skillId.endsWith('defensive_aura')) return 3 + lvl * 2;
    return artSkillOculumCost(skillId);
  }

  int skillInvestmentMax(String skillId) {
    final lvl = skillLevel(skillId).clamp(1, artSkillMaxLevel(skillId)).toInt();
    if (skillId.endsWith('non_newtonian_liquid')) return 3;
    if (skillId.endsWith('useful_physical_activity')) return 3;
    if (skillId.endsWith('blue_control')) {
      return lvl <= 1
          ? 5
          : lvl == 2
          ? 20
          : 30;
    }
    if (skillId.endsWith('flaming_form')) return skillInvestmentMin(skillId);
    if (skillId.endsWith('lightning_form')) return skillInvestmentMin(skillId);
    if (skillId.endsWith('runic_guards')) return 6;
    if (skillId.endsWith('fast_upgrade')) {
      if (lvl <= 1) return 5;
      if (lvl == 2) return 6;
      if (lvl == 3) return 9;
      if (lvl == 4) return 12;
      return 15;
    }
    if (skillId.endsWith('defensive_aura')) return skillInvestmentMin(skillId);
    return artSkillOculumCost(skillId);
  }

  String skillInvestmentResourceIt(String skillId) {
    if (skillId.endsWith('runic_guards')) return 'kg Metallo';
    if (skillId.endsWith('fast_upgrade')) return 'Obser';
    return 'Ocu';
  }

  String skillInvestmentResourceEn(String skillId) {
    if (skillId.endsWith('runic_guards')) return 'kg Metal';
    if (skillId.endsWith('fast_upgrade')) return 'Obser';
    return 'Ocu';
  }

  String artSkillCostLabel(String skillId) {
    if (!skillId.startsWith('modern_school_art_') &&
        !skillId.startsWith('kingi_blue_art_') &&
        !skillId.startsWith('defiled_postea_art_')) {
      return '${artSkillOculumCost(skillId)} Ocu';
    }
    final minCost = skillInvestmentMin(skillId);
    final maxCost = skillInvestmentMax(skillId);
    final resource = widget.linguaInglese
        ? skillInvestmentResourceEn(skillId)
        : skillInvestmentResourceIt(skillId);
    if (minCost == maxCost) return '$minCost $resource';
    return '$minCost-$maxCost $resource';
  }

  int spendOculumInvestment(String skillId) {
    final minCost = skillInvestmentMin(skillId);
    final maxCost = skillInvestmentMax(skillId);
    if (oculumCharges < minCost) {
      final skill = findArtSkillDef(skillId);
      textIt =
          '${skill?.nameIt ?? 'Skill Oculum'}\n\nOculum insufficiente: richiede almeno $minCost Oculum e può investirne fino a $maxCost. Ne hai $oculumCharges.';
      textEn =
          '${skill?.nameEn ?? 'Oculum Skill'}\n\nNot enough Oculum: it needs at least $minCost Oculum and can invest up to $maxCost. You have $oculumCharges.';
      return -1;
    }
    final spent = min(maxCost, oculumCharges).toInt();
    oculumCharges -= spent;
    return spent;
  }

  int spendObserInvestment(String skillId) {
    final minCost = skillInvestmentMin(skillId);
    final maxCost = skillInvestmentMax(skillId);
    if (obserInRun < minCost) {
      final skill = findArtSkillDef(skillId);
      textIt =
          '${skill?.nameIt ?? 'Skill'}\n\nObser insufficienti: richiede almeno $minCost Obser e può investirne fino a $maxCost. Ne hai $obserInRun.';
      textEn =
          '${skill?.nameEn ?? 'Skill'}\n\nNot enough Obser: it needs at least $minCost Obser and can invest up to $maxCost. You have $obserInRun.';
      return -1;
    }
    final spent = min(maxCost, obserInRun).toInt();
    obserInRun -= spent;
    return spent;
  }

  int spendPosteaMetalInvestment(String skillId) {
    final minCost = skillInvestmentMin(skillId);
    final maxCost = skillInvestmentMax(skillId);
    if (posteaRunicMetalKg < minCost) {
      final skill = findArtSkillDef(skillId);
      textIt =
          '${skill?.nameIt ?? 'Skill Postea'}\n\nMetallo Runico Postea insufficiente: richiede almeno $minCost kg e può investirne fino a $maxCost kg. Ne hai $posteaRunicMetalLabel.';
      textEn =
          '${skill?.nameEn ?? 'Postea Skill'}\n\nNot enough Postea Runic Metal: it needs at least $minCost kg and can invest up to $maxCost kg. You have $posteaRunicMetalLabel.';
      return -1;
    }
    final spent = min(maxCost, posteaRunicMetalKg).toInt();
    posteaRunicMetalKg -= spent;
    return spent;
  }

  bool hasRunFlag(String flag) {
    return runBoons.contains(flag) || purchasedRelics.contains(flag);
  }

  bool hasTechniqueSkill(String techniqueId) {
    // Regola stretta:
    // CM / AoE VC / AoE CM non si sbloccano con una skill generica.
    // Servono item, pergamene, o una Skill Oculum specifica che nel suo ID
    // viene trattata come tecnica speciale.
    for (final skillId in unlockedActiveArtSkillIds()) {
      if (!skillUnlocked(skillId)) continue;

      if (techniqueId == 'cm' &&
          (skillId.endsWith('_skill_04') || skillId.endsWith('_skill_11'))) {
        return true;
      }

      if (techniqueId == 'aoe_vc' &&
          (skillId.endsWith('_skill_08') || skillId.endsWith('_skill_12'))) {
        return true;
      }

      if (techniqueId == 'aoe_cm' &&
          (skillId.endsWith('_skill_05') || skillId.endsWith('_skill_12'))) {
        return true;
      }
    }

    return false;
  }

  bool canUseCmAttack() {
    return hasRunFlag('unlock_cm_attack') ||
        hasRunFlag('scroll_materia_hand') ||
        hasTechniqueSkill('cm');
  }

  bool canUseAoeVc() {
    return posteaGrenadesEquipped ||
        hasRunFlag('unlock_aoe_vc') ||
        hasRunFlag('scroll_bouncing_eye') ||
        hasTechniqueSkill('aoe_vc');
  }

  bool canUseAoeCm() {
    return hasRunFlag('unlock_aoe_cm') ||
        hasRunFlag('scroll_materia_hand') ||
        hasTechniqueSkill('aoe_cm');
  }

  void showLockedTechniqueMessage(String labelIt, String labelEn) {
    setState(() {
      textIt =
          '$labelIt bloccato.\n\n'
          'Nel minigioco l’attacco base usa solo VC.\n'
          'CM e AoE richiedono item specifici, pergamene occulte o Skill compatibili della tua Art.';
      textEn =
          '$labelEn locked.\n\n'
          'In the minigame, the basic attack uses only VC.\n'
          'CM and AoE require specific items, occult scrolls or compatible Skills from your Art.';
    });
  }

  void applyElementalComboBonus() {
    if (!inCombat || enemyParty.length <= 1) return;

    if (activeElementId == 'fire' && enemyWeak > 0) {
      enemyBurn += 2;
      elementalComboHits++;
    }

    if (activeElementId == 'lightning' && enemyParty.length >= 2) {
      final chainTarget = enemyParty.length > 1
          ? enemyParty[1]
          : enemyParty.first;
      final chainDamage = 3 + totalOculum + currentFloor;
      chainTarget.hp = max(0, chainTarget.hp - chainDamage).toInt();
      elementalComboHits++;
      textIt += '\nCombo elementale: il Fulmine salta su un secondo bersaglio.';
      textEn += '\nElemental combo: Lightning jumps to a second target.';
    }

    if (activeElementId == 'ice' && enemyBurn > 0) {
      enemyWeak += 2;
      elementalComboHits++;
      textIt += '\nCombo elementale: shock termico, +2 Debolezza.';
      textEn += '\nElemental combo: thermal shock, +2 Weakness.';
    }

    if (hasRunFlag('scroll_bouncing_eye') && enemyParty.length >= 2) {
      final second = enemyParty[1];
      final bounceDamage = max(1, totalDamage ~/ 3 + totalOculum);
      second.hp = max(0, second.hp - bounceDamage).toInt();
      textIt +=
          '\nOcchio Rimbalzante: $bounceDamage danni extra a un secondo nemico.';
      textEn += '\nBouncing Eye: $bounceDamage extra damage to a second enemy.';
    }
  }

  bool isDrownedArtSkill(String skillId) {
    final skill = findArtSkillDef(skillId);
    if (skill == null || activeArt == null) return false;

    final nameIt = skill.nameIt.toLowerCase();
    final nameEn = skill.nameEn.toLowerCase();

    return activeArt!.elementId == 'water' &&
        (skillId.endsWith('_skill_04') ||
            nameIt.contains('annegamento') ||
            nameEn.contains('drowning'));
  }

  bool hasUnlockedDrownedChainSkill() {
    if (activeArt == null || activeArt!.elementId != 'water') return false;
    final skillIds = ensureThreeRandomSkillsForArt(activeArt!);
    return skillIds.any((id) => isDrownedArtSkill(id) && skillUnlocked(id));
  }

  void armDrownedArtNecromancy({required int power}) {
    drownedSummonTurns = max(drownedSummonTurns, 3).toInt();
    enemyWeak += 1 + power;
    nextEnemyWeakened = true;

    addLog(
      t(
        'Catena d’Annegamento attiva: i prossimi nemici caduti possono restare come Affogati.',
        'Drowning Chain active: the next fallen enemies may remain as Drowned.',
      ),
    );
  }

  bool spendOculumForSkill(String skillId) {
    final cost = artSkillOculumCost(skillId);
    if (cost <= 0) return true;
    if (oculumCharges < cost) {
      final skill = findArtSkillDef(skillId);
      textIt =
          '${skill?.nameIt ?? 'Skill Oculum'}\n\nOculum insufficiente: costa $cost cariche Oculum, ne hai $oculumCharges.';
      textEn =
          '${skill?.nameEn ?? 'Oculum Skill'}\n\nNot enough Oculum: it costs $cost Oculum charges, you have $oculumCharges.';
      return false;
    }
    oculumCharges -= cost;
    return true;
  }

  void useArtSkill(String skillId) {
    if (!runActive || gameOver || enemyTurnPending || activeArt == null) {
      return;
    }
    final skill = findArtSkillDef(skillId);
    if (skill == null || !skillUnlocked(skillId)) return;

    setState(() {
      clearChoices();
      final lvl = skillLevel(skillId);
      final spentOculum = artSkillOculumCost(skillId);
      if (!spendOculumForSkill(skillId)) {
        return;
      }
      oculumSkillCasts++;
      final power = max(1, min(artSkillMaxLevel(skillId), lvl)).toInt();

      if (skillId.startsWith('modern_school_art_')) {
        if (skillId.endsWith('non_newtonian_liquid')) {
          final spent = spendOculumInvestment(skillId);
          if (spent < 0) return;
          final resilienceGain = spent * (1 + power);
          final shield = 8 + spent * 8 + power * 6;
          final damageBonus = spent * power + totalOculum;
          dungeonResilienza += resilienceGain;
          runDamageBonus += max(1, damageBonus ~/ 2);
          gainPlayerShield(shield);
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            final target = firstAliveEnemy();
            if (target != null) {
              final damage = max(1, damageBonus + totalDefense ~/ 5);
              target.hp = max(0, target.hp - damage).toInt();
              target.slowTurns = max(target.slowTurns, power).toInt();
              enemyWeak += power >= 2 ? 1 : 0;
              textIt =
                  '${skill.nameIt}\n\n'
                  'Investi $spent Oculum nel liquido non newtoniano.\n'
                  '+$resilienceGain Resilienza, +$shield Scudo, +${max(1, damageBonus ~/ 2)} danni run.\n'
                  'Il liquido si indurisce su ${target.nameIt}: $damage danni e lentezza.';
              textEn =
                  '${skill.nameEn}\n\n'
                  'You invest $spent Oculum into the non-Newtonian liquid.\n'
                  '+$resilienceGain Resilience, +$shield Shield, +${max(1, damageBonus ~/ 2)} run damage.\n'
                  'The liquid hardens on ${target.nameEn}: $damage damage and slow.';
              defeatDeadEnemiesFromParty();
              if (enemyParty.isEmpty) {
                completeCombatVictory();
                return;
              }
              syncPrimaryEnemyFromParty();
              enemyTurn();
            }
          } else {
            textIt =
                '${skill.nameIt}\n\n'
                'Investi $spent Oculum: il liquido resta addosso come protezione scolastica stranamente efficace.\n'
                '+$resilienceGain Resilienza, +$shield Scudo, +${max(1, damageBonus ~/ 2)} danni run.';
            textEn =
                '${skill.nameEn}\n\n'
                'You invest $spent Oculum: the liquid stays on you as weirdly effective school protection.\n'
                '+$resilienceGain Resilience, +$shield Shield, +${max(1, damageBonus ~/ 2)} run damage.';
          }
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('useful_physical_activity')) {
          final spent = spendOculumInvestment(skillId);
          if (spent < 0) return;
          final statGain = spent * power;
          dungeonResilienza += statGain;
          dungeonVolonta += statGain;
          dungeonMateria += statGain;
          dungeonOculum += max(1, spent ~/ 2);
          dodgeCharges += power;
          reactionAvailable = true;
          runCritBonus += spent + power;
          textIt =
              '${skill.nameIt}\n\n'
              'Investi $spent Oculum in una lezione di ginnastica finalmente utile.\n'
              '+$statGain Resilienza, Volontà e Materia; +${max(1, spent ~/ 2)} Oculum run; +$power schivate; reazione pronta.';
          textEn =
              '${skill.nameEn}\n\n'
              'You invest $spent Oculum into a finally useful PE lesson.\n'
              '+$statGain Resilience, Will and Materia; +${max(1, spent ~/ 2)} run Oculum; +$power dodges; reaction ready.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('time_math')) {
          final bucket = max(0, room ~/ 6);
          final flag = 'modern_school_time_rewind_$bucket';
          if (runBoons.contains(flag)) {
            textIt =
                '${skill.nameIt}\n\nLa formula è già stata usata in questo blocco di 6 stanze. Potrai riarmarla dal prossimo blocco.';
            textEn =
                '${skill.nameEn}\n\nThe formula has already been used in this 6-room block. You can arm it again in the next block.';
            return;
          }
          runBoons.add(flag);
          rebirthBlessingActive = true;
          final bonus = power >= 3 ? 6 : 3;
          runCritBonus += bonus;
          runDamageBonus += bonus ~/ 2;
          gainPlayerShield(10 + bonus * 2);
          textIt =
              '${skill.nameIt}\n\n'
              'Armi il ritorno temporale per questo blocco di 6 stanze.\n'
              'Se muori, torni all ultima azione con +$bonus. +${10 + bonus * 2} Scudo ora.';
          textEn =
              '${skill.nameEn}\n\n'
              'You arm the time rewind for this 6-room block.\n'
              'If you die, you return to the last action with +$bonus. +${10 + bonus * 2} Shield now.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }
      }

      if (skillId.startsWith('kingi_blue_art_')) {
        if (skillId.endsWith('blue_control')) {
          final spent = spendOculumInvestment(skillId);
          if (spent < 0) return;
          final materiaGain = power <= 1
              ? 5 + spent
              : power == 2
              ? 10 + spent * 3
              : 16 + spent * 4;
          final hitBonus = power <= 1
              ? 3
              : power == 2
              ? 6
              : 9;
          final fireDamage = power <= 1
              ? 0
              : power == 2
              ? 5
              : 12;
          dungeonMateria += materiaGain;
          runDamageBonus += hitBonus + fireDamage;
          enemyWeak += power;
          nextEnemyWeakened = true;
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            final target = firstAliveEnemy();
            if (target != null) {
              final damage = materiaGain + hitBonus + fireDamage;
              target.hp = max(0, target.hp - damage).toInt();
              target.burnTurns = max(target.burnTurns, power).toInt();
              textIt =
                  '${skill.nameIt}\n\n'
                  'Investi $spent Oculum nel blu. +$materiaGain Materia.\n'
                  'L avversario sbaglia contro un falso te: +$hitBonus per colpirlo, +$fireDamage fuoco. $damage danni a ${target.nameIt}.';
              textEn =
                  '${skill.nameEn}\n\n'
                  'You invest $spent Oculum into blue. +$materiaGain Materia.\n'
                  'The enemy misses against a fake you: +$hitBonus to hit it, +$fireDamage fire. $damage damage to ${target.nameEn}.';
              defeatDeadEnemiesFromParty();
              if (enemyParty.isEmpty) {
                completeCombatVictory();
                return;
              }
              syncPrimaryEnemyFromParty();
              enemyTurn();
            }
          } else {
            textIt =
                '${skill.nameIt}\n\n'
                'Investi $spent Oculum nel blu. +$materiaGain Materia, +${hitBonus + fireDamage} danni run e il prossimo nemico sarà ingannato.';
            textEn =
                '${skill.nameEn}\n\n'
                'You invest $spent Oculum into blue. +$materiaGain Materia, +${hitBonus + fireDamage} run damage and the next enemy will be deceived.';
          }
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('flaming_form')) {
          final spent = spendOculumInvestment(skillId);
          if (spent < 0) return;
          final volGain = power <= 1
              ? 3
              : power == 2
              ? 6
              : 9;
          final matGain = power <= 1
              ? 2
              : power == 2
              ? 4
              : 6;
          final buff = power <= 1
              ? 10
              : power == 2
              ? 15
              : 22;
          final turns = power <= 1
              ? 6
              : power == 2
              ? 10
              : 14;
          dungeonVolonta += volGain;
          dungeonMateria += matGain;
          runDefenseBonus += buff;
          runDamageBonus += buff;
          runBoons.add('kingi_flame_active');
          gainPlayerShield(buff + spent);
          textIt =
              '${skill.nameIt}\n\n'
              'Spendi $spent Oculum. Per $turns turni narrativi bruci blu scuro.\n'
              '+$volGain Volontà, +$matGain Materia, +$buff difesa e danni, +${buff + spent} Scudo.';
          textEn =
              '${skill.nameEn}\n\n'
              'You spend $spent Oculum. For $turns narrative turns you burn dark blue.\n'
              '+$volGain Will, +$matGain Materia, +$buff defense and damage, +${buff + spent} Shield.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('lightning_form')) {
          if (!runBoons.contains('kingi_flame_active')) {
            textIt =
                '${skill.nameIt}\n\nDevi prima attivare Forma Fiammeggiante.';
            textEn = '${skill.nameEn}\n\nYou must activate Flaming Form first.';
            return;
          }
          final spent = spendOculumInvestment(skillId);
          if (spent < 0) return;
          final matGain = power <= 1
              ? 6
              : power == 2
              ? 36
              : 54;
          final volGain = power <= 1
              ? 9
              : power == 2
              ? 51
              : 72;
          final reactionBonus = power <= 1 ? 1 : 2;
          dungeonMateria += matGain;
          dungeonVolonta += volGain;
          dodgeCharges += max(1, totalOculum);
          reactionAvailable = true;
          runDamageBonus += power <= 1
              ? 8
              : power == 2
              ? 20
              : 32;
          runDefenseBonus += power <= 1
              ? 8
              : power == 2
              ? 20
              : 32;
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            final damage =
                (power <= 1
                    ? 12
                    : power == 2
                    ? 24
                    : 42) +
                spent +
                totalOculum;
            for (final enemy in enemyParty.where((enemy) => enemy.hp > 0)) {
              enemy.hp = max(0, enemy.hp - damage).toInt();
            }
            textIt =
                '${skill.nameIt}\n\n'
                'Le fiamme si plasmano in fulmini. Spendi $spent Oculum.\n'
                '+$matGain Materia, +$volGain Volontà, +$reactionBonus reazioni blu, $damage danni ad area.';
            textEn =
                '${skill.nameEn}\n\n'
                'Flames shape into lightning. You spend $spent Oculum.\n'
                '+$matGain Materia, +$volGain Will, +$reactionBonus blue reactions, $damage area damage.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            textIt =
                '${skill.nameIt}\n\n'
                'Le fiamme si plasmano in fulmini. Spendi $spent Oculum.\n'
                '+$matGain Materia, +$volGain Volontà, schivate +${max(1, totalOculum)} e reazione pronta.';
            textEn =
                '${skill.nameEn}\n\n'
                'Flames shape into lightning. You spend $spent Oculum.\n'
                '+$matGain Materia, +$volGain Will, +${max(1, totalOculum)} dodges and ready reaction.';
          }
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }
      }

      if (skillId.startsWith('defiled_postea_art_')) {
        if (skillId.endsWith('runic_guards')) {
          final kg = spendPosteaMetalInvestment(skillId);
          if (kg < 0) return;
          final guardRes = 5 + 10 * kg + power * 3;
          final guardVol = 25 + 5 * kg + power * 5;
          final guardMat = 25 + 5 * kg + power * 5;
          final shield = guardRes * 2 + guardVol ~/ 2;
          final explosion = 50 + kg * 12 + power * 10;
          dungeonResilienza += max(1, kg);
          dungeonVolonta += power;
          dungeonMateria += power;
          gainPlayerShield(shield);
          skellyGuardCharges += 2 + power;
          runDamageBonus += explosion ~/ 10;
          textIt =
              '${skill.nameIt}\n\n'
              'Consumi $kg kg di Metallo Runico Postea. Metallo rimasto: $posteaRunicMetalLabel.\n'
              'Evochi due guardie runiche di metà livello: Resilienza $guardRes, Volontà $guardVol, Materia $guardMat.\n'
              '+$shield Scudo, +${2 + power} cariche guardia, esplosione a morte $explosion.';
          textEn =
              '${skill.nameEn}\n\n'
              'You consume $kg kg of Postea Runic Metal. Metal left: $posteaRunicMetalLabel.\n'
              'You summon two half-level runic guards: Resilience $guardRes, Will $guardVol, Materia $guardMat.\n'
              '+$shield Shield, +${2 + power} guard charges, death explosion $explosion.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('fast_upgrade')) {
          final spent = spendObserInvestment(skillId);
          if (spent < 0) return;
          final perObser = power;
          final gain = spent * perObser;
          dungeonResilienza += gain;
          dungeonVolonta += gain;
          dungeonMateria += gain;
          dungeonOculum += gain;
          runCritBonus += power >= 5 ? gain ~/ 2 : power;
          if (power >= 3) gainPlayerShield(gain * 2);
          if (power >= 4) reactionAvailable = true;
          if (power >= 5) gainOculumCharges(1);
          final freeLine = runBoons.contains('defiled_fast_upgrade_used')
              ? ''
              : '\nPrima volta in giornata: azione gratuita.';
          runBoons.add('defiled_fast_upgrade_used');
          textIt =
              '${skill.nameIt}\n\n'
              'Spendi $spent Obser. +$perObser a tutte le stats per Obser: +$gain Resilienza, Volontà, Materia e Oculum.$freeLine';
          textEn =
              '${skill.nameEn}\n\n'
              'You spend $spent Obser. +$perObser to all stats per Obser: +$gain Resilience, Will, Materia and Oculum.${freeLine.isEmpty ? '' : '\nFirst daily use: free action.'}';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('defensive_aura')) {
          final spent = spendOculumInvestment(skillId);
          if (spent < 0) return;
          final fireDefense = 5 + totalOculum * 3 + power * 8 + spent;
          final shield = fireDefense + totalDefense ~/ 3;
          elementalResist['fire'] = (elementalResist['fire'] ?? 0) + power;
          elementalResist['postea'] =
              (elementalResist['postea'] ?? 0) + (power >= 3 ? 1 : 0);
          runDefenseBonus += fireDefense ~/ 4;
          gainPlayerShield(shield);
          if (power >= 4) {
            for (final ally in activeAllies) {
              if (ally.id == 'postea_elite_guard') {
                posteaEliteGuardShield += shield ~/ 2;
              }
            }
          }
          if (power >= 5) runDamageBonus += fireDefense ~/ 5;
          textIt =
              '${skill.nameIt}\n\n'
              'Spendi $spent Oculum. Aura difensiva: +$fireDefense difesa da fuoco, +$shield Scudo.\n'
              'Cooldown narrativo 3 azioni. Forma $power: resistenza Postea ${power >= 3 ? 'attiva' : 'non ancora attiva'}.';
          textEn =
              '${skill.nameEn}\n\n'
              'You spend $spent Oculum. Defensive aura: +$fireDefense fire defense, +$shield Shield.\n'
              'Narrative cooldown 3 actions. Form $power: Postea resistance ${power >= 3 ? 'active' : 'not active yet'}.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }
      }

      if (skillId.startsWith('hoshy_oculum_art_')) {
        if (skillId.endsWith('stelle_comete')) {
          final bonus = power == 1
              ? 2
              : power == 2
              ? 4
              : 8;
          final damage = max(1, totalVc + bonus + spentOculum * 2);

          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            final target = firstAliveEnemy();
            if (target == null) {
              completeCombatVictory();
              return;
            }
            target.hp = max(0, target.hp - damage).toInt();
            enemyWeak += power;
            textIt =
                'Stelle Comete Lvl ${power == 1
                    ? 'I'
                    : power == 2
                    ? 'II'
                    : 'III'}\n\n'
                'Lanci $spentOculum Oculum in piccole stelle comete.\n'
                'Danni: Volontà $totalVc + $bonus + Oculum immesso x2 = $damage su ${target.nameIt}.';
            textEn =
                'Comet Stars Lvl ${power == 1
                    ? 'I'
                    : power == 2
                    ? 'II'
                    : 'III'}\n\n'
                'You throw $spentOculum Oculum as small comet stars.\n'
                'Damage: Will $totalVc + $bonus + invested Oculum x2 = $damage to ${target.nameEn}.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            runCritBonus += 1 + power;
            textIt =
                'Stelle Comete\n\nLe stelle restano in orbita: +${1 + power} critico fino alla fine della pressione.';
            textEn =
                'Comet Stars\n\nThe stars remain in orbit: +${1 + power} critical until pressure ends.';
          }

          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('esplosione_contatto')) {
          final damage = max(1, totalDefense * 2 + spentOculum * 4);
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            for (final enemy in enemyParty.where((enemy) => enemy.hp > 0)) {
              enemy.hp = max(0, enemy.hp - damage).toInt();
              enemy.defense = max(0, enemy.defense - power).toInt();
            }
            textIt =
                'Esplosione a Contatto\n\n'
                'La pelle diventa miccia. Danno ad area: Difesa $totalDefense x2 + Oculum immesso = $damage.';
            textEn =
                'Contact Burst\n\n'
                'Your skin becomes a fuse. Area damage: Defense $totalDefense x2 + invested Oculum = $damage.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            final shield = totalDefense + spentOculum * 8;
            gainPlayerShield(shield);
            textIt =
                'Esplosione a Contatto\n\nTrattieni lo scoppio sotto pelle: +$shield Scudo.';
            textEn =
                'Contact Burst\n\nYou hold the burst under your skin: +$shield Shield.';
          }

          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('forma_stellare')) {
          final turns = max(1, spentOculum + power - 1);
          final cmGain = spentOculum * 2 + power;
          final vcGain = spentOculum + power;
          dungeonMateria += cmGain;
          dungeonVolonta += vcGain;
          dodgeCharges += turns;
          gainPlayerShield(10 * turns);
          textIt =
              'Forma Stellare\n\n'
              'Per $turns turni narrativi voli in forma stellare.\n'
              '+$cmGain CM, +$vcGain VC, +$dodgeCharges schivate totali, +${10 * turns} Scudo.';
          textEn =
              'Stellar Form\n\n'
              'For $turns narrative turns you fly in stellar form.\n'
              '+$cmGain CM, +$vcGain VC, +$dodgeCharges total dodges, +${10 * turns} Shield.';

          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }
      }

      if (skillId.startsWith('autumn_oculum_art_')) {
        if (skillId.endsWith('tempest_falling_leaves')) {
          final baseDamage = max(1, totalOculum * (power == 1 ? 1 : 2));
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            for (final enemy in enemyParty.where((enemy) => enemy.hp > 0)) {
              final damage = max(1, baseDamage - enemy.defense ~/ 4);
              enemy.hp = max(0, enemy.hp - damage).toInt();
              if (power >= 2) {
                enemy.attackDebuffTurns = max(enemy.attackDebuffTurns, 2);
                enemy.attackDebuffValue = max(
                  enemy.attackDebuffValue,
                  2 + totalOculum ~/ 3,
                );
                enemy.slowTurns = max(enemy.slowTurns, 1);
              }
            }
            if (power >= 2) enemyWeak += 2;
            textIt =
                'Tempest of the Falling Leaves\n\n'
                'Un tornado di foglie secche e vento taglia l area.\n'
                'Danno Oculum ad area: $baseDamage.'
                '${power >= 2 ? '\nStatus Rinsecchito: attacco nemico ridotto, nemici avvicinati e +2 Fragilità.' : ''}';
            textEn =
                'Tempest of the Falling Leaves\n\n'
                'A tornado of dry leaves and wind cuts the area.\n'
                'Oculum area damage: $baseDamage.'
                '${power >= 2 ? '\nWithered: enemy attack reduced, enemies pulled close and +2 Fragility.' : ''}';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            enemyWeak += power;
            textIt =
                'Tempest of the Falling Leaves\n\nIl vento si prepara: +$power Fragilità al prossimo contatto.';
            textEn =
                'Tempest of the Falling Leaves\n\nThe wind prepares: +$power Fragility on the next contact.';
          }
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('death_birth')) {
          final gained = max(1, spentOculum ~/ 3);
          dungeonMateria += gained;
          gainPlayerShield(gained * 4);
          textIt =
              'Dalla Morte Nasce Sempre Qualcosa\n\n'
              'Gli Oculum spesi marciscono e diventano Materia.\n'
              '+$gained Materia run, +${gained * 4} Scudo.';
          textEn =
              'From Death Something Always Grows\n\n'
              'Spent Oculum decays into Materia.\n'
              '+$gained run Materia, +${gained * 4} Shield.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('autumn_regeneration')) {
          final windy = activeArt?.elementId == 'wind' ? 1 : 0;
          final regen = min(3, 1 + currentFloor ~/ 5 + windy).toInt();
          oculumCharges = min(oculumMaxCharges, oculumCharges + regen);
          playerAttackDebuffTurns = max(playerAttackDebuffTurns, 1);
          playerAttackDebuffValue = max(playerAttackDebuffValue, 3);
          playerSlowTurns = max(playerSlowTurns, 1);
          textIt =
              'Rigenerazione Dell Autunno\n\n'
              'Respiri in un area ventosa: +$regen Oculum.\n'
              'Svantaggio per il turno: attacco ridotto e lentezza.';
          textEn =
              'Autumn Regeneration\n\n'
              'You breathe in a windy area: +$regen Oculum.\n'
              'Disadvantage this turn: reduced attack and slow.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }
      }

      if (skillId.startsWith('swiftness_martial_art_')) {
        if (skillId.endsWith('chain_damage')) {
          if (!spendRunStat('mat', 2)) {
            textIt = 'Chain Damage richiede 2 Materia della run.';
            textEn = 'Chain Damage requires 2 run Materia.';
            oculumCharges += spentOculum;
            return;
          }
          final hits = 1 + _random.nextInt(6);
          var total = 0;
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            for (var i = 0; i < hits; i++) {
              final targets = enemyParty
                  .where((enemy) => enemy.hp > 0)
                  .toList();
              if (targets.isEmpty) break;
              final target = targets[i % targets.length];
              final damage = max(1, ((totalDamage + 5) / pow(2, i)).round());
              target.hp = max(0, target.hp - damage).toInt();
              total += damage;
            }
            textIt =
                'Chain Damage\n\n'
                '$hits colpi concatenati. Ogni colpo dimezza il danno precedente.\n'
                'Costo: 2 Materia. +5 danni per il turno.\n'
                'Danni totali: $total.';
            textEn =
                'Chain Damage\n\n'
                '$hits chained hits. Each hit halves the previous damage.\n'
                'Cost: 2 Materia. +5 damage this turn.\n'
                'Total damage: $total.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            combo += 1;
            textIt = 'Chain Damage\n\nIl corpo prepara una catena: +1 combo.';
            textEn = 'Chain Damage\n\nThe body prepares a chain: +1 combo.';
          }
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('vanish_tp')) {
          var highestEnemyGrade = widget.playerGrade;
          for (final enemy in enemyParty) {
            highestEnemyGrade = max(highestEnemyGrade, enemy.grade).toInt();
          }
          final gradePenalty = max(0, highestEnemyGrade - widget.playerGrade);
          final dodges = max(0, 1 + _random.nextInt(4) - gradePenalty);
          if (dungeonMateria >= 3) {
            spendRunStat('mat', 3);
          } else if (dungeonVolonta >= 3) {
            spendRunStat('vol', 3);
          } else {
            textIt = 'Vanish TP richiede 3 Materia o 3 Volontà della run.';
            textEn = 'Vanish TP requires 3 run Materia or 3 run Will.';
            oculumCharges += spentOculum;
            return;
          }
          dodgeCharges += dodges;
          reactionAvailable = true;
          textIt =
              'Vanish TP\n\n'
              'Schivi $dodges colpi potenziali'
              '${gradePenalty > 0 ? ' (-$gradePenalty per Grado avversario superiore)' : ''}.\n'
              '+$dodges schivate, reazione pronta.';
          textEn =
              'Vanish TP\n\n'
              'You dodge $dodges potential hits'
              '${gradePenalty > 0 ? ' (-$gradePenalty from higher enemy Grade)' : ''}.\n'
              '+$dodges dodges, reaction ready.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }

        if (skillId.endsWith('critical_flow')) {
          runCritBonus += 4 + power;
          combo += 2;
          textIt =
              'Flusso Critico\n\n'
              'Il ritmo marziale accelera: +${4 + power} critico e +2 combo.';
          textEn =
              'Critical Flow\n\n'
              'The martial rhythm accelerates: +${4 + power} critical and +2 combo.';
          progressQuest('oculum');
          progressSkillQuest(amount: power);
          return;
        }
      }

      if (isDrownedArtSkill(skillId)) {
        armDrownedArtNecromancy(power: power);

        if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
          final target = firstAliveEnemy();
          if (target == null) {
            completeCombatVictory();
            return;
          }
          final damage = 4 + oculumArtPower + power * 3;
          target.hp = max(0, target.hp - damage).toInt();
          enemyWeak += power;

          textIt =
              '${skill.nameIt}\n\n'
              'La Catena d’Annegamento si chiude sulle caviglie del nemico.\n'
              'Infliggi $damage danni acqua morta a ${target.nameIt}.\n'
              'Se i nemici cadono in questo fight, fino a $maxTemporaryDrowned resteranno come Affogati temporanei'
              '${maxTemporaryDrowned == 4 ? ' grazie al Romanzo.' : '.'}\n'
              'Affogati attivi ora: $activeTemporaryDrownedCount/$maxTemporaryDrowned.';
          textEn =
              '${skill.nameEn}\n\n'
              'The Drowning Chain closes around the enemy ankles.\n'
              'You deal $damage dead-water damage to ${target.nameEn}.\n'
              'If enemies fall in this fight, up to $maxTemporaryDrowned will remain as Temporary Drowned'
              '${maxTemporaryDrowned == 4 ? ' thanks to the Novel.' : '.'}\n'
              'Drowned active now: $activeTemporaryDrownedCount/$maxTemporaryDrowned.';

          defeatDeadEnemiesFromParty();
          if (enemyParty.isEmpty) {
            completeCombatVictory();
            return;
          }

          syncPrimaryEnemyFromParty();
          enemyTurn();
        } else {
          textIt =
              '${skill.nameIt}\n\n'
              'Prepari la necromanzia acquatica: il prossimo fight potrà lasciare Affogati temporanei nel party.\n'
              'Limite: $maxTemporaryDrowned Affogati${maxTemporaryDrowned == 4 ? ' con Romanzo' : ''}.';
          textEn =
              '${skill.nameEn}\n\n'
              'You prepare aquatic necromancy: the next fight may leave Temporary Drowned in the party.\n'
              'Limit: $maxTemporaryDrowned Drowned${maxTemporaryDrowned == 4 ? ' with the Novel' : ''}.';
        }

        progressQuest('oculum');
        progressSkillQuest(amount: 2);
        saveRunCheckpoint(
          reasonIt: 'Catena d’Annegamento registrata nel salvataggio.',
          reasonEn: 'Drowning Chain recorded into the save.',
        );
        return;
      }

      if (isThornWhipSkill(skillId)) {
        final baseBonus = 3 + oculumArtPower;
        final iiActive = canUseThornWhipII(skillId);
        final damageBonus = baseBonus + (iiActive ? 4 + evonestProof : 0);
        thornWhipRollBonus = max(thornWhipRollBonus, iiActive ? 2 : 1).toInt();
        runDamageBonus += damageBonus;
        enemyWeak += iiActive ? 2 : 1;

        if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
          final target = firstAliveEnemy();
          if (target == null) {
            completeCombatVictory();
            return;
          }
          final damage = damageBonus + power * 2;
          target.hp = max(0, target.hp - damage).toInt();

          textIt =
              'Frusta di Spine ${iiActive ? 'II' : 'I'}\n\n'
              'Una frusta di spine lunga fino a 6 metri nasce come arto in più.\n'
              '+$thornWhipRollBonus ai roll se utile alla scena.\n'
              '+$damageBonus danni run temporanei.\n'
              'Colpisci ${target.nameIt}: $damage danni.\n'
              '${iiActive ? 'Evonest/Eiva ha ascoltato: le spine tengono meglio e spezzano la guardia.' : 'II resta sigillata: [Richiede: parla con un Eiva].'}';
          textEn =
              'Thorn Whip ${iiActive ? 'II' : 'I'}\n\n'
              'A thorn whip up to 6 meters long grows like an extra limb.\n'
              '+$thornWhipRollBonus to rolls when useful to the scene.\n'
              '+$damageBonus temporary run damage.\n'
              'You hit ${target.nameEn}: $damage damage.\n'
              '${iiActive ? 'Evonest/Eiva has listened: the thorns hold better and break guard.' : 'II remains sealed: [Requires: speak with an Eiva].'}';

          defeatDeadEnemiesFromParty();
          if (enemyParty.isEmpty) {
            completeCombatVictory();
            return;
          }
          syncPrimaryEnemyFromParty();
          enemyTurn();
        } else {
          gainPlayerShield(iiActive ? 12 : 6);
          nextEnemyWeakened = true;
          textIt =
              'Frusta di Spine ${iiActive ? 'II' : 'I'}\n\n'
              'Crei una frusta di spine lunga fino a 6 metri: arto in più, appiglio, presa o minaccia.\n'
              '+$thornWhipRollBonus ai roll se utile alla scena.\n'
              '+$damageBonus danni fino alla prossima pressione del dungeon.\n'
              '${iiActive ? '+12 Scudo: le spine sono state riconosciute da un Eiva.' : '+6 Scudo. II sigillata: [Richiede: parla con un Eiva].'}';
          textEn =
              'Thorn Whip ${iiActive ? 'II' : 'I'}\n\n'
              'You create a thorn whip up to 6 meters long: extra limb, grip, hold or threat.\n'
              '+$thornWhipRollBonus to rolls when useful to the scene.\n'
              '+$damageBonus damage until the next dungeon pressure.\n'
              '${iiActive ? '+12 Shield: the thorns were recognized by an Eiva.' : '+6 Shield. II sealed: [Requires: speak with an Eiva].'}';
        }

        progressQuest('oculum');
        progressSkillQuest(amount: iiActive ? 2 : 1);
        saveRunCheckpoint(
          reasonIt: 'Frusta di Spine registrata nel salvataggio.',
          reasonEn: 'Thorn Whip recorded into the save.',
        );
        return;
      }

      switch (skill.kind) {
        case 'damage':
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            final target = firstAliveEnemy();
            if (target == null) {
              completeCombatVictory();
              return;
            }
            final damage =
                8 + oculumArtPower + power * 5 + elementalDamageBonus();
            target.hp = max(0, target.hp - damage).toInt();
            applyElementalHitEffects(target);
            syncPrimaryEnemyFromParty();

            textIt =
                '${skill.nameIt}\n\n'
                'Infliggi $damage danni con Oculum a ${target.nameIt}.';
            textEn =
                '${skill.nameEn}\n\n'
                'You deal $damage Oculum damage to ${target.nameEn}.';

            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }

            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            textIt =
                '${skill.nameIt}\n\nQuesta Skill rende meglio in combattimento.';
            textEn = '${skill.nameEn}\n\nThis Skill works better in combat.';
          }
          break;

        case 'defense':
          final shield = 12 + willMateriaDefense ~/ 2 + power * 8;
          gainPlayerShield(shield);
          reactionAvailable = true;
          textIt = '${skill.nameIt}\n\n+$shield Scudo. Reazione ripristinata.';
          textEn = '${skill.nameEn}\n\n+$shield Shield. Reaction restored.';
          break;

        case 'heal':
          final heal = 10 + oculumArtPower + power * 6;
          playerHp = min(playerMaxHp, playerHp + heal);
          textIt = '${skill.nameIt}\n\n+$heal HP.';
          textEn = '${skill.nameEn}\n\n+$heal HP.';
          break;

        case 'control':
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            final target = firstAliveEnemy();
            if (target == null) {
              completeCombatVictory();
              return;
            }
            enemyWeak += 1 + power;
            target.attack = max(1, target.attack - power).toInt();
            syncPrimaryEnemyFromParty();
            textIt = '${skill.nameIt}\n\n${target.nameIt} indebolito.';
            textEn = '${skill.nameEn}\n\n${target.nameEn} weakened.';
          } else {
            nextEnemyWeakened = true;
            textIt = '${skill.nameIt}\n\nIl prossimo nemico sarà indebolito.';
            textEn = '${skill.nameEn}\n\nThe next enemy will be weakened.';
          }
          break;

        case 'utility':
          dungeonOculum += 1;
          if (power >= 2) gainOculumCharges(1);
          textIt = '${skill.nameIt}\n\n+1 Oculum nella run.';
          textEn = '${skill.nameEn}\n\n+1 Oculum during the run.';
          break;

        case 'special':
          if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
            final target = firstAliveEnemy();
            if (target == null) {
              completeCombatVictory();
              return;
            }
            final damage = 12 + totalDamage ~/ 2 + oculumArtPower + power * 8;
            target.hp = max(0, target.hp - damage).toInt();
            enemyWeak += power;
            textIt =
                '${skill.nameIt}\n\nFrattura rara del Fato: $damage danni a ${target.nameIt}.';
            textEn =
                '${skill.nameEn}\n\nRare fracture of Fate: $damage damage to ${target.nameEn}.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            final shield = 10 + power * 10;
            gainPlayerShield(shield);
            nextRoomSafe = true;
            textIt =
                '${skill.nameIt}\n\n+$shield Scudo. Prossima stanza sicura.';
            textEn = '${skill.nameEn}\n\n+$shield Shield. Next room is safe.';
          }
          break;
      }

      progressQuest('oculum');
      progressSkillQuest(amount: 1);
    });
  }

  void ensureBossHasUnlockedArtSkill() {
    if (!inCombat || !enemyIsBoss || activeArt == null) return;

    final skillIds = ensureThreeRandomSkillsForArt(activeArt!);
    if (skillIds.any(skillUnlocked)) return;
    if (skillIds.isEmpty) return;

    final picked = skillIds.first;
    final progress = artSkillProgress.putIfAbsent(
      picked,
      () => _ArtSkillProgress(skillId: picked),
    );
    progress.level = max(progress.level, 1).toInt();
    applyArtSkillPassive(picked);

    final skill = findArtSkillDef(picked);
    addLog(
      t(
        'Il boss forza l’Oculum: ${skill?.nameIt ?? picked} si sblocca.',
        'The boss forces the Oculum: ${skill?.nameEn ?? picked} unlocks.',
      ),
    );

    textIt +=
        '\n\nIl boss non ti lascia con tre Skill sigillate: ${skill?.nameIt ?? picked} si sblocca d’emergenza.';
    textEn +=
        '\n\nThe boss does not leave you with three sealed Skills: ${skill?.nameEn ?? picked} emergency-unlocks.';
  }

  void showArtSkillChoices() {
    if (activeArt == null) return;

    setState(() {
      ensureBossHasUnlockedArtSkill();
      clearChoices(mode: 'skills');
      showCombatActions = true;
      final skillIds = ensureThreeRandomSkillsForArt(activeArt!);

      final drownedHintIt = activeArt!.elementId == 'water'
          ? '\n\nArt degli Affogati: Catena d’Annegamento è garantita. Usala prima o durante un fight: i nemici caduti resteranno come Affogati temporanei, 3 base o 4 con Romanzo.'
          : '';
      final drownedHintEn = activeArt!.elementId == 'water'
          ? '\n\nDrowned Art: Drowning Chain is guaranteed. Use it before or during a fight: fallen enemies will remain as Temporary Drowned, 3 base or 4 with the Novel.'
          : '';

      textIt =
          'Skill Oculum della tua Art:\n\n'
          '${buildArtSkillSummaryText()}\n\n'
          'Puoi usare le Skill sbloccate. Quelle bloccate richiedono quest.'
          '$drownedHintIt';
      textEn =
          'Oculum Skills of your Art:\n\n'
          '${buildArtSkillSummaryText()}\n\n'
          'You can use unlocked Skills. Locked ones require quests.'
          '$drownedHintEn';

      for (final id in skillIds) {
        final skill = findArtSkillDef(id);
        if (skill == null) continue;
        final unlocked = skillUnlocked(id);
        eventChoices.add(
          _DungeonChoice(
            labelIt:
                '${unlocked ? 'Usa' : 'Bloccata'}: ${skill.nameIt} • ${skillLevelLabel(id)} • ${artSkillCostLabel(id)}',
            labelEn:
                '${unlocked ? 'Use' : 'Locked'}: ${skill.nameEn} • ${skillLevelLabel(id)} • ${artSkillCostLabel(id)}',
            icon: unlocked ? Icons.auto_fix_high : Icons.lock,
            color: unlocked ? elementColor(activeElementId) : Colors.grey,
            onPressed: unlocked
                ? () => useArtSkill(id)
                : () {
                    setState(() {
                      textIt =
                          '${skill.nameIt}\n\nBloccata.\nQuest: $activeSkillQuestIt\n$activeSkillQuestProgress/$activeSkillQuestGoal';
                      textEn =
                          '${skill.nameEn}\n\nLocked.\nQuest: $activeSkillQuestEn\n$activeSkillQuestProgress/$activeSkillQuestGoal';
                    });
                  },
          ),
        );
      }

      saveRunCheckpoint(
        reasonIt: 'Skill Oculum registrate nel salvataggio.',
        reasonEn: 'Oculum Skills recorded into the save.',
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Aggiorna Skill',
          labelEn: 'Refresh Skills',
          icon: Icons.refresh,
          color: Colors.blueGrey,
          onPressed: showArtSkillChoices,
        ),
      );
    });
  }

  void treasureEvent() {
    clearChoices(mode: 'event');
    textIt =
        'Tesoro trovato.\n\n'
        'Il forziere ha forma: quello che prendi può lasciare segni nello sprite.';
    textEn =
        'Treasure found.\n\n'
        'The chest has shape: what you take may leave marks on your sprite.';
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Prendi Obser e Dust',
        labelEn: 'Take Obser and Dust',
        icon: Icons.auto_awesome,
        color: widget.tertiaryColor,
        onPressed: takeTreasureCurrency,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Cerca oggetto con forma',
        labelEn: 'Search shaped item',
        icon: Icons.category,
        color: Colors.greenAccent,
        onPressed: takeTreasureShape,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Rompi il forziere',
        labelEn: 'Break the chest',
        icon: Icons.hardware,
        color: Colors.orangeAccent,
        onPressed: breakTreasureChest,
      ),
    );
  }

  void takeTreasureCurrency() {
    setState(() {
      clearChoices();
      final rewardObser =
          2 + runGrade + currentFloor + skillEventBonus('treasure');
      final rewardDust = chance(35) ? 1 : 0;
      obserInRun += rewardObser;
      ascensionDustInRun += rewardDust;
      final metalKg = maybeGainPosteaRunicMetalFromTreasure();
      progressQuest('treasure');
      progressSkillQuest(amount: 1 + skillEventBonus('treasure'));
      textIt =
          'Prendi il contenuto del tesoro.\n+$rewardObser Obser\n+$rewardDust Ascension Dust.'
          '${metalKg > 0 ? '\n+$metalKg kg Metallo Runico Postea.' : ''}';
      textEn =
          'You take the treasure contents.\n+$rewardObser Obser\n+$rewardDust Ascension Dust.'
          '${metalKg > 0 ? '\n+$metalKg kg Postea Runic Metal.' : ''}';
    });
  }

  bool get canFindPosteaRunicMetal =>
      activeArt?.effectId == 'defiled_postea_art' ||
      selectedRunArtIds.contains('defiled_postea_art') ||
      unlockedArtIds.contains('defiled_postea_art');

  int maybeGainPosteaRunicMetalFromTreasure() {
    if (!canFindPosteaRunicMetal) return 0;
    if (!chance(activeArt?.effectId == 'defiled_postea_art' ? 55 : 28)) {
      return 0;
    }
    final kg = 1 + _random.nextInt(6);
    posteaRunicMetalKg += kg;
    return kg;
  }

  void takeTreasureShape() {
    setState(() {
      clearChoices();
      final pool = _uniqueDrops.toList()..shuffle(_random);
      final drop = pool.first;
      inventoryDrops.add(drop);
      final metalKg = maybeGainPosteaRunicMetalFromTreasure();
      progressQuest('treasure');
      progressQuest('drop');
      progressSkillQuest(amount: 1);
      textIt =
          'Trovi un oggetto con forma:\n${drop.nameIt}\n\n'
          'Entra nello zaino e genera un piccolo sprite finché lo porti con te.'
          '${metalKg > 0 ? '\n\nTra le cuciture trovi anche +$metalKg kg Metallo Runico Postea.' : ''}';
      textEn =
          'You find a shaped item:\n${drop.nameEn}\n\n'
          'It enters the bag and generates a small sprite while you carry it.'
          '${metalKg > 0 ? '\n\nInside the seams you also find +$metalKg kg Postea Runic Metal.' : ''}';
    });
  }

  void breakTreasureChest() {
    setState(() {
      clearChoices();
      final damage = max(1, 5 + currentFloor - totalDefense ~/ 4);
      playerHp = max(0, playerHp - damage).toInt();
      ascensionDustInRun += 1;
      runDamageBonus += 1;
      progressQuest('treasure');
      textIt =
          'Rompi il forziere e ne tieni una scheggia.\n-$damage HP\n+1 Dust\n+1 danno run.';
      textEn =
          'You break the chest and keep one shard.\n-$damage HP\n+1 Dust\n+1 run damage.';
      if (playerHp <= 0) gameOver = true;
    });
  }

  void safeRoomEvent() {
    final heal = max(
      1,
      5 +
          currentFloor +
          skillEventBonus('rest') +
          calendarEventBonus('rest') -
          calendarDangerBonus('rest'),
    );
    playerHp = min(playerMaxHp, playerHp + heal);
    gainPlayerShield(max(0, 8 + currentFloor + calendarEventBonus('rest') * 2));
    if (roomsWithoutDamage >= 3) progressQuest('no_damage');
    textIt =
        'Stanza sicura.\n${cyclePhaseLine()}\n+$heal HP\n+${max(0, 8 + currentFloor + calendarEventBonus('rest') * 2)} Scudo.';
    textEn =
        'Safe room.\n${cyclePhaseLine()}\n+$heal HP\n+${max(0, 8 + currentFloor + calendarEventBonus('rest') * 2)} Shield.';
  }

  void trapEvent() {
    clearChoices(mode: 'event');
    textIt =
        'Trappola di palpebre nere.\n\n'
        'La stanza si stringe in tre corsie. Puoi leggerla con l Oculum, forzarla con il corpo o giocare il minigioco di schivata.';
    textEn =
        'Black eyelid trap.\n\n'
        'The room tightens into three lanes. You can read it with Oculum, force it with your body or play the dodge minigame.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Leggi con Oculum',
        labelEn: 'Read with Oculum',
        icon: Icons.visibility,
        color: const Color(0xFF8B5CF6),
        onPressed: resolveTrapWithStats,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Forza il meccanismo',
        labelEn: 'Force mechanism',
        icon: Icons.fitness_center,
        color: Colors.orangeAccent,
        onPressed: forceTrapMechanism,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Minigioco schivata',
        labelEn: 'Dodge minigame',
        icon: Icons.gamepad,
        color: Colors.tealAccent,
        onPressed: startTrapMiniGame,
      ),
    );
    if (eventChoices.isEmpty) {
      final bonus = max(totalVc, totalCm) + skillEventBonus('trap');
      final difficulty = 12 + currentFloor * 2 + calendarDangerBonus('trap');
      if (bonus + _random.nextInt(20) + 1 >= difficulty) {
        gainPlayerShield(12 + currentFloor);
        textIt = 'Trappola letta con l’Oculum.\n+${12 + currentFloor} Scudo.';
        textEn = 'Trap read through Oculum.\n+${12 + currentFloor} Shield.';
      } else {
        final damage = max(
          1,
          10 +
              currentFloor * 2 +
              calendarDangerBonus('trap') * 2 -
              totalDefense ~/ 3,
        );
        playerHp = max(0, playerHp - damage).toInt();
        textIt = 'Trappola di palpebre nere.\nSubisci $damage danni.';
        textEn = 'Black eyelid trap.\nYou take $damage damage.';
        if (playerHp <= 0) gameOver = true;
      }
    }
  }

  void resolveTrapWithStats() {
    setState(() {
      clearChoices();
      final bonus = max(totalVc, totalCm) + skillEventBonus('trap');
      final difficulty = 12 + currentFloor * 2 + calendarDangerBonus('trap');
      if (bonus + _random.nextInt(20) + 1 >= difficulty) {
        gainPlayerShield(12 + currentFloor);
        textIt = 'Trappola letta con l Oculum.\n+${12 + currentFloor} Scudo.';
        textEn = 'Trap read through Oculum.\n+${12 + currentFloor} Shield.';
      } else {
        final damage = max(
          1,
          10 +
              currentFloor * 2 +
              calendarDangerBonus('trap') * 2 -
              totalDefense ~/ 3,
        );
        playerHp = max(0, playerHp - damage).toInt();
        textIt = 'La lettura fallisce.\nSubisci $damage danni.';
        textEn = 'The reading fails.\nYou take $damage damage.';
        if (playerHp <= 0) gameOver = true;
      }
    });
  }

  void forceTrapMechanism() {
    setState(() {
      clearChoices();
      final damage = max(1, 6 + currentFloor * 2 - totalDefense ~/ 2);
      playerHp = max(0, playerHp - damage).toInt();
      runDamageBonus += 1;
      textIt =
          'Sfianchi il meccanismo a colpi.\nSubisci $damage danni.\n+1 danno run.';
      textEn =
          'You break the mechanism by force.\nYou take $damage damage.\n+1 run damage.';
      if (playerHp <= 0) gameOver = true;
    });
  }

  void startTrapMiniGame() {
    setState(() {
      clearChoices();
      trapMiniGameActive = true;
      trapPlayerLane = 1;
      trapStep = 0;
      trapHits = 0;
      trapReward = 8 + currentFloor * 2;
      trapStepsTotal = 6 + min(4, currentFloor ~/ 3);
      trapFocusCharges = 1 + (oculumCharges > 0 ? 1 : 0);
      trapBestCombo = 0;
      trapCurrentCombo = 0;
      trapRevealedStep = -1;
      textIt =
          'Minigioco trappola: muoviti tra le tre corsie ed evita gli occhi neri.\n'
          'Puoi usare Leggi per rivelare una corsia sicura.';
      textEn =
          'Trap minigame: move across three lanes and avoid the black eyes.\n'
          'You can use Read to reveal a safe lane.';
    });
  }

  List<int> trapHazardsForStep(int step) {
    const patterns = [
      [0],
      [2],
      [0, 1],
      [1, 2],
      [0, 2],
      [1],
    ];
    final pattern = patterns[(step + currentFloor) % patterns.length];
    if (currentFloor < 5 || step.isEven) return pattern;
    return pattern.length == 1
        ? [pattern.first, (pattern.first + 1) % 3]
        : pattern;
  }

  int trapSafeLaneForStep(int step) {
    final hazards = trapHazardsForStep(step);
    final safe = <int>[0, 1, 2].where((lane) => !hazards.contains(lane));
    return safe.isEmpty ? 1 : safe.first;
  }

  void trapMiniGameReveal() {
    if (!trapMiniGameActive || trapFocusCharges <= 0) return;
    setState(() {
      trapFocusCharges--;
      trapRevealedStep = trapStep;
      final laneNameIt = [
        'sinistra',
        'centro',
        'destra',
      ][trapSafeLaneForStep(trapStep)];
      final laneNameEn = [
        'left',
        'center',
        'right',
      ][trapSafeLaneForStep(trapStep)];
      textIt =
          'Leggi la trappola: per questo passo e sicura la corsia $laneNameIt.';
      textEn =
          'You read the trap: for this step, the safe lane is $laneNameEn.';
    });
  }

  void trapMiniGameMove(int delta) {
    if (!trapMiniGameActive) return;
    setState(() {
      trapPlayerLane = (trapPlayerLane + delta).clamp(0, 2).toInt();
      final hazards = trapHazardsForStep(trapStep);
      if (hazards.contains(trapPlayerLane)) {
        trapHits++;
        trapCurrentCombo = 0;
      } else {
        trapCurrentCombo++;
        trapBestCombo = max(trapBestCombo, trapCurrentCombo);
      }
      trapStep++;
      trapRevealedStep = -1;
      if (trapStep >= trapStepsTotal) finishTrapMiniGame();
    });
  }

  void finishTrapMiniGame() {
    trapMiniGameActive = false;
    clearChoices();
    final comboShield = trapBestCombo >= 3 ? trapBestCombo * 2 : 0;
    final damage = max(
      0,
      trapHits * (5 + currentFloor) - totalDefense ~/ 4 - trapBestCombo,
    );
    if (damage > 0) playerHp = max(0, playerHp - damage).toInt();
    final shield = max(0, trapReward - trapHits * 4 + comboShield);
    gainPlayerShield(shield);
    if (trapHits == 0) {
      runCritBonus += 3;
      gainOculumCharges(1);
      progressSkillQuest(amount: 2);
    }
    textIt =
        'Minigioco trappola concluso.\n'
        'Colpi subiti: $trapHits\n'
        'Combo migliore: $trapBestCombo\n'
        '${damage > 0 ? 'Danni: $damage\n' : ''}'
        '+$shield Scudo'
        '${trapHits == 0 ? '\nPerfetto: +3 critico, +1 Oculum e +2 progressi Skill.' : ''}';
    textEn =
        'Trap minigame complete.\n'
        'Hits taken: $trapHits\n'
        'Best combo: $trapBestCombo\n'
        '${damage > 0 ? 'Damage: $damage\n' : ''}'
        '+$shield Shield'
        '${trapHits == 0 ? '\nPerfect: +3 critical, +1 Oculum and +2 Skill progress.' : ''}';
    if (playerHp <= 0) gameOver = true;
  }

  void shrineEvent() {
    final choice = _random.nextInt(4);
    switch (choice) {
      case 0:
        dungeonOculum += 1;
        textIt = 'Altare dell’Oculum Vivo.\n+1 Oculum.';
        textEn = 'Living Oculum Altar.\n+1 Oculum.';
        break;
      case 1:
        gainPlayerShield(25);
        textIt = 'Altare della Palpebra.\n+25 Scudo.';
        textEn = 'Eyelid Altar.\n+25 Shield.';
        break;
      case 2:
        runCritBonus += 5;
        textIt = 'Altare dell’Accurate Sun.\n+5 critico.';
        textEn = 'Accurate Sun Altar.\n+5 critical.';
        break;
      default:
        runLifesteal += 1;
        textIt = 'Altare della Devil Moon.\n+1 furto vita.';
        textEn = 'Devil Moon Altar.\n+1 lifesteal.';
    }
  }

  void oculumEvent() {
    gainOculumCharges(1);
    dungeonOculum += 1;
    progressSkillQuest(amount: 1);
    textIt = 'Trovi un nucleo di Oculum.\n+1 Oculum\n+1 carica Oculum.';
    textEn = 'You find an Oculum core.\n+1 Oculum\n+1 Oculum charge.';
  }

  void occultVaultEvent() {
    clearChoices();

    textIt =
        'Camera Occulta.\n\n'
        'La stanza non ha porta: ha un caricatore d’ossa e tre palpebre come serrature.\n'
        'Puoi rischiare un fight élite per ottenere una scelta di potere.';
    textEn =
        'Occult Vault.\n\n'
        'The room has no door: it has a bone chamber and three eyelids as locks.\n'
        'You may risk an elite fight to obtain a power choice.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Apri la Camera Occulta',
        labelEn: 'Open the Occult Vault',
        icon: Icons.lock_open,
        color: const Color(0xFFA78BFA),
        onPressed: () {
          setState(() {
            clearChoices();
            eliteVaultsCleared++;
            spawnEnemy(elite: true);
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Prendi solo un frammento sicuro',
        labelEn: 'Take only a safe fragment',
        icon: Icons.diamond,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            ascensionDustInRun += 1;
            textIt =
                'Prendi un frammento sicuro.\n'
                '+1 Ascension Dust.\n\n'
                'La Camera Occulta si richiude: non puoi ripetere questa scelta.';
            textEn =
                'You take a safe fragment.\n'
                '+1 Ascension Dust.\n\n'
                'The Occult Vault closes: you cannot repeat this choice.';
          });
        },
      ),
    );
  }

  void ascensionChoiceEvent() {
    clearChoices();

    final choices = <_DungeonChoice>[
      _DungeonChoice(
        labelIt: 'Calice dell’Oculum: +2 Oculum, +1 carica',
        labelEn: 'Oculum Chalice: +2 Oculum, +1 charge',
        icon: Icons.local_drink,
        color: const Color(0xFF8B5CF6),
        onPressed: () {
          setState(() {
            clearChoices();
            dungeonOculum += 2;
            gainOculumCharges(1);
            textIt = 'Bevi dal Calice dell’Oculum.\n+2 Oculum, +1 carica.';
            textEn =
                'You drink from the Oculum Chalice.\n+2 Oculum, +1 charge.';
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Sigillo Balistico: +3 danni, sblocca AoE VC',
        labelEn: 'Ballistic Seal: +3 damage, unlocks VC AoE',
        icon: Icons.gps_fixed,
        color: Colors.deepOrangeAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            runDamageBonus += 3;
            if (!runBoons.contains('unlock_aoe_vc')) {
              runBoons.add('unlock_aoe_vc');
            }
            textIt =
                'Sigillo Balistico assorbito.\n+3 danni, AoE VC sbloccato.';
            textEn = 'Ballistic Seal absorbed.\n+3 damage, VC AoE unlocked.';
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Mano della Materia: +2 difesa, sblocca CM',
        labelEn: 'Materia Hand: +2 defense, unlocks CM',
        icon: Icons.front_hand,
        color: widget.primaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            runDefenseBonus += 2;
            if (!runBoons.contains('scroll_materia_hand')) {
              runBoons.add('scroll_materia_hand');
            }
            textIt =
                'Mano della Materia risvegliata.\n+2 difesa, CM sbloccato.';
            textEn = 'Materia Hand awakened.\n+2 defense, CM unlocked.';
          });
        },
      ),
      _DungeonChoice(
        labelIt: 'Carica Elementale: +2 cariche Oculum',
        labelEn: 'Elemental Charge: +2 Oculum charges',
        icon: Icons.bolt,
        color: elementColor(activeElementId),
        onPressed: () {
          setState(() {
            clearChoices();
            gainOculumCharges(2);
            textIt = 'Carica Elementale.\n+2 cariche Oculum.';
            textEn = 'Elemental Charge.\n+2 Oculum charges.';
          });
        },
      ),
    ];

    choices.shuffle(_random);
    eventChoices.addAll(
      choices.take(hasRunFlag('scroll_double_breath') ? 4 : 3),
    );

    textIt =
        'Scelta di Ascensione.\n\n'
        'Una coppa, un sigillo, una mano e una carica tremano nello stesso occhio.\n'
        'Scegli un solo potere.';
    textEn =
        'Ascension Choice.\n\n'
        'A chalice, a seal, a hand and a charge tremble inside the same eye.\n'
        'Choose one power.';
  }

  void mirrorOfTheRunEvent() {
    clearChoices();

    textIt =
        'Specchio della Run.\n\n'
        'Non riflette il volto: riflette la statistica che hai trascurato.\n'
        'Scegli una sola benedizione.';
    textEn =
        'Run Mirror.\n\n'
        'It does not reflect your face: it reflects the stat you neglected.\n'
        'Choose one blessing.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+1 Oculum e +1 carica',
        labelEn: '+1 Oculum and +1 charge',
        icon: Icons.visibility,
        color: const Color(0xFF8B5CF6),
        onPressed: () {
          setState(() {
            clearChoices();
            dungeonOculum += 1;
            gainOculumCharges(1);
            textIt =
                'Lo specchio apre una pupilla piccola.\n+1 Oculum, +1 carica.';
            textEn = 'The mirror opens a small pupil.\n+1 Oculum, +1 charge.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+18 Scudo',
        labelEn: '+18 Shield',
        icon: Icons.shield,
        color: Colors.greenAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            gainPlayerShield(18);
            textIt = 'Lo specchio si chiude come una palpebra.\n+18 Scudo.';
            textEn = 'The mirror closes like an eyelid.\n+18 Shield.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+2 danni run',
        labelEn: '+2 run damage',
        icon: Icons.flash_on,
        color: Colors.amber,
        onPressed: () {
          setState(() {
            clearChoices();
            runDamageBonus += 2;
            textIt = 'Lo specchio si incrina in avanti.\n+2 danni run.';
            textEn = 'The mirror cracks forward.\n+2 run damage.';
          });
        },
      ),
    );
  }

  void woundedAllyEvent() {
    clearChoices();

    textIt =
        'Alleato Ferito.\n\n'
        'Una figura buona respira dietro una porta bassa.\n'
        'Puoi spendere risorse per aiutarla o prendere una ricompensa più fredda.';
    textEn =
        'Wounded Ally.\n\n'
        'A good figure breathes behind a low door.\n'
        'You can spend resources to help them or take a colder reward.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Aiutalo (-5 Obser, cura e possibile NPC)',
        labelEn: 'Help them (-5 Obser, heal and possible NPC)',
        icon: Icons.volunteer_activism,
        color: Colors.tealAccent,
        onPressed: () {
          setState(() {
            clearChoices();

            if (obserInRun < 5) {
              playerHp = min(playerMaxHp, playerHp + 8);
              textIt =
                  'Non hai abbastanza Obser, ma resti ad ascoltare.\n+8 HP.';
              textEn = 'You lack Obser, but you stay and listen.\n+8 HP.';
              return;
            }

            obserInRun -= 5;
            playerHp = min(playerMaxHp, playerHp + 18);
            woundedAllyAssistReady = true;

            if (_goodNpcs.isNotEmpty && chance(35)) {
              final locked = _goodNpcs
                  .where((npc) => !unlockedNpcIds.contains(npc.id))
                  .toList();

              if (locked.isNotEmpty) {
                final npc = locked[_random.nextInt(locked.length)];
                unlockedNpcIds.add(npc.id);
                _savePermanentProgress();

                textIt =
                    'Aiuti l’alleato ferito.\n'
                    '+18 HP.\n'
                    'Nel prossimo fight proverà ad attaccare con te: 15% chance, +500 danni critici.\n'
                    'NPC sbloccato: ${npc.nameIt}.';
                textEn =
                    'You help the wounded ally.\n'
                    '+18 HP.\n'
                    'In the next fight they may attack with you: 15% chance, +500 critical damage.\n'
                    'NPC unlocked: ${npc.nameEn}.';
                return;
              }
            }

            textIt =
                'Aiuti l’alleato ferito.\n+18 HP.\nNel prossimo fight proverà ad attaccare con te: 15% chance, +500 danni critici.';
            textEn =
                'You help the wounded ally.\n+18 HP.\nIn the next fight they may attack with you: 15% chance, +500 critical damage.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Prendi la borsa (+7 Obser)',
        labelEn: 'Take the bag (+7 Obser)',
        icon: Icons.backpack,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            obserInRun += 7;
            textIt =
                'Prendi la borsa senza guardarlo negli occhi.\n'
                '+7 Obser.\n'
                'Il dungeon ricorda questa piccola crudeltà.';
            textEn =
                'You take the bag without looking into their eyes.\n'
                '+7 Obser.\n'
                'The dungeon remembers this small cruelty.';
          });
        },
      ),
    );
  }

  void cursedObserChestEvent() {
    clearChoices();

    textIt =
        'Forziere degli Obser Falsi.\n\n'
        'Ogni moneta ha un occhio inciso troppo bene.\n'
        'Puoi aprirlo o lasciarlo respirare.';
    textEn =
        'False Obser Chest.\n\n'
        'Every coin has an eye engraved too well.\n'
        'You can open it or let it breathe.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Apri il forziere',
        labelEn: 'Open the chest',
        icon: Icons.inventory_2,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();

            final good = _random.nextInt(100) < 62;
            if (good) {
              final reward = 8 + currentFloor;
              obserInRun += reward;
              textIt = 'Gli Obser erano veri abbastanza.\n+$reward Obser.';
              textEn = 'The Obser were true enough.\n+$reward Obser.';
            } else {
              final damage = max(1, 8 + currentFloor * 2 - totalDefense ~/ 5);
              playerHp = max(0, playerHp - damage).toInt();
              enemyWeak += 1;
              textIt =
                  'Il forziere ti morde la mano.\n'
                  'Subisci $damage danni.\n'
                  '+1 Debolezza ai prossimi nemici.';
              textEn =
                  'The chest bites your hand.\n'
                  'You take $damage damage.\n'
                  '+1 Weakness to next enemies.';
              if (playerHp <= 0 && !tryConsumeRebirthBlessing()) {
                finishRun(victorious: false);
              }
            }
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Lascialo respirare (+1 Dust)',
        labelEn: 'Let it breathe (+1 Dust)',
        icon: Icons.air,
        color: const Color(0xFFC4B5FD),
        onPressed: () {
          setState(() {
            clearChoices();
            ascensionDustInRun += 1;
            textIt =
                'Non apri il forziere.\nLa serratura sospira.\n+1 Ascension Dust.';
            textEn =
                'You do not open the chest.\nThe lock sighs.\n+1 Ascension Dust.';
          });
        },
      ),
    );
  }

  void elementalWellEvent() {
    clearChoices();

    final element = _elements.where((e) => e.id != 'neutral').toList()
      ..shuffle(_random);
    final chosen = element.first;

    textIt =
        'Pozzo Elementale — ${chosen.nameIt}.\n\n'
        'L’acqua non cade: sale verso l’occhio.\n'
        'Scegli una sola immersione.';
    textEn =
        'Elemental Well — ${chosen.nameEn}.\n\n'
        'The water does not fall: it rises toward the eye.\n'
        'Choose one immersion.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+3 resistenza ${chosen.nameIt}',
        labelEn: '+3 ${chosen.nameEn} resistance',
        icon: Icons.water_drop,
        color: chosen.color,
        onPressed: () {
          setState(() {
            clearChoices();
            elementalResist[chosen.id] = (elementalResist[chosen.id] ?? 0) + 3;
            textIt = 'Ti immergi nel pozzo.\n+3 resistenza ${chosen.nameIt}.';
            textEn = 'You enter the well.\n+3 ${chosen.nameEn} resistance.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+1 Oculum, ma perdi 8 HP',
        labelEn: '+1 Oculum, but lose 8 HP',
        icon: Icons.visibility,
        color: const Color(0xFF8B5CF6),
        onPressed: () {
          setState(() {
            clearChoices();
            dungeonOculum += 1;
            playerHp = max(1, playerHp - 8).toInt();
            textIt = 'Bevi dal pozzo.\n+1 Oculum.\n-8 HP.';
            textEn = 'You drink from the well.\n+1 Oculum.\n-8 HP.';
          });
        },
      ),
    );
  }

  void arcanePedestalEvent() {
    clearChoices();

    textIt =
        'Altare Arcano.\n\n'
        'Un cerchio basso ruota sul pavimento: sembra fatto per chi combatte muovendosi, non restando fermo.\n'
        'Puoi trasformarlo in una Skill, in una Art o in un incontro NPC della run.';
    textEn =
        'Arcane Pedestal.\n\n'
        'A low circle rotates on the floor: it seems made for someone who fights by moving, not standing still.\n'
        'You can turn it into a Skill, an Art or a run NPC encounter.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Studia il cerchio',
        labelEn: 'Study the circle',
        icon: Icons.auto_fix_high,
        color: const Color(0xFF60A5FA),
        onPressed: () {
          setState(() {
            clearChoices();
            progressSkillQuest(amount: 3 + skillEventBonus('treasure'));
            runCritBonus += 3;
            dodgeCharges += 1;
            textIt =
                'Studi il cerchio arcano.\n\n'
                '+3 progressi Skill Oculum\n'
                '+3 critico run\n'
                '+1 schivata.';
            textEn =
                'You study the arcane circle.\n\n'
                '+3 Oculum Skill progress\n'
                '+3 run critical\n'
                '+1 dodge.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Estrai una Art',
        labelEn: 'Extract an Art',
        icon: Icons.bolt,
        color: const Color(0xFFFFD36A),
        onPressed: () {
          setState(() {
            clearChoices();
            final targetIds = [
              'arcane_step_art',
              'frost_rings_art',
              'ember_orbit_art',
              'tidal_seal_art',
            ];
            final locked = _allArts
                .where((art) => targetIds.contains(art.effectId))
                .where((art) => !unlockedArtIds.contains(art.effectId))
                .toList();
            if (locked.isNotEmpty) {
              final art = locked[_random.nextInt(locked.length)];
              unlockedArtIds.add(art.effectId);
              _savePermanentProgress();
              textIt =
                  'Art estratta: ${art.nameIt}.\nApparira tra le Art delle prossime run.';
              textEn =
                  'Art extracted: ${art.nameEn}.\nIt will appear among future run Arts.';
            } else {
              progressSkillQuest(amount: 5);
              gainOculumCharges(1);
              textIt =
                  'Conosci già queste Art. Il cerchio diventa pratica pura: +5 progressi Skill e +1 Oculum.';
              textEn =
                  'You already know these Arts. The circle becomes pure practice: +5 Skill progress and +1 Oculum.';
            }
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Chiama un duellante',
        labelEn: 'Call a duelist',
        icon: Icons.person_add,
        color: Colors.tealAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            const ids = [
              'arcane_duelist_mira',
              'frost_ring_apprentice',
              'ember_orbit_piper',
              'tidal_seal_mender',
            ];
            final pool =
                _goodNpcs
                    .where((npc) => ids.contains(npc.id))
                    .where(
                      (npc) => !activeAllies.any((ally) => ally.id == npc.id),
                    )
                    .toList()
                  ..shuffle(_random);
            if (pool.isEmpty) {
              gainPlayerShield(18);
              textIt =
                  'Nessun duellante risponde. L altare si chiude in Scudo: +18.';
              textEn =
                  'No duelist answers. The pedestal closes into Shield: +18.';
              return;
            }
            final npc = pool.first;
            unlockedNpcIds.add(npc.id);
            final joined = addAllyToParty(
              npc,
              replaceIfFull: false,
              save: false,
            );
            _savePermanentProgress();
            textIt =
                '${npc.nameIt} appare dal cerchio.\n\n'
                '${npc.descIt}\n\n'
                '${joined ? 'Entra nel party della run.' : 'Il party e pieno: resta sbloccato per le prossime run.'}';
            textEn =
                '${npc.nameEn} appears from the circle.\n\n'
                '${npc.descEn}\n\n'
                '${joined ? 'Joins the run party.' : 'The party is full: unlocked for future runs.'}';
          });
        },
      ),
    );
  }

  void alchemistSatchelEvent() {
    clearChoices();

    textIt =
        'Borsa dell’Alchimista.\n\n'
        'Dentro tintinnano fiale e denti.\n'
        'Scegli una sola tasca.';
    textEn =
        'Alchemist Satchel.\n\n'
        'Inside, vials and teeth clink.\n'
        'Choose one pocket.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+2 Consumabili Minori',
        labelEn: '+2 Raw Vitaliums',
        icon: Icons.science,
        color: Colors.greenAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            addQuickPotion('minor', amount: 2);
            textIt =
                'Prendi 2 Vitalium Grezzo.\nInventario: ${quickInventorySummary()}';
            textEn =
                'You take two Raw Vitaliums.\nInventory: ${quickInventorySummary()}';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+1 Fiala Oculum',
        labelEn: '+1 Oculum Vial',
        icon: Icons.visibility,
        color: const Color(0xFF8B5CF6),
        onPressed: () {
          setState(() {
            clearChoices();
            addQuickPotion('oculum', amount: 1);
            textIt =
                'Prendi una fiala Oculum.\nInventario: ${quickInventorySummary()}';
            textEn =
                'You take an Oculum vial.\nInventory: ${quickInventorySummary()}';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+1 Fumo Fuga',
        labelEn: '+1 Escape Smoke',
        icon: Icons.smoke_free,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            addQuickPotion('smoke', amount: 1);
            textIt =
                'Prendi un Fumo Fuga.\nInventario: ${quickInventorySummary()}';
            textEn =
                'You take an Escape Smoke.\nInventory: ${quickInventorySummary()}';
          });
        },
      ),
    );
  }

  void forgottenArmoryEvent() {
    clearChoices();

    textIt =
        'Armeria.\n\n'
        'Le armi pendono da ganci arrugginiti. Alcune ti guardano.';
    textEn =
        'Armory.\n\n'
        'Weapons hang from rusty hooks. Some watch you.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Tenta sblocco arma',
        labelEn: 'Try weapon unlock',
        icon: Icons.hardware,
        color: const Color(0xFFFFD36A),
        onPressed: () {
          setState(() {
            clearChoices();
            final before = unlockedWeaponIds.length;
            tryUnlockRandomWeapon();
            if (unlockedWeaponIds.length > before) {
              textIt = 'Nuova arma iniziale sbloccata.';
              textEn = 'New starting weapon unlocked.';
            } else {
              runDamageBonus += 2;
              textIt = 'Nessuna arma nuova.\n+2 danni run.';
              textEn = 'No new weapon.\n+2 run damage.';
            }
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+Dust',
        labelEn: '+Dust',
        icon: Icons.construction,
        color: Colors.amber,
        onPressed: () {
          setState(() {
            clearChoices();
            final dust = 1 + currentFloor ~/ 3;
            ascensionDustInRun += dust;
            textIt = 'Smonti parti utili.\n+$dust Ascension Dust.';
            textEn = 'You dismantle useful parts.\n+$dust Ascension Dust.';
          });
        },
      ),
    );
  }

  void oculumLibraryEvent() {
    clearChoices();

    textIt =
        'Biblioteca degli Occhi.\n\n'
        'Ogni scaffale trattiene una tecnica.';
    textEn =
        'Library of Eyes.\n\n'
        'Each shelf holds a technique.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Studia Art casuale',
        labelEn: 'Study random Art',
        icon: Icons.auto_stories,
        color: const Color(0xFFA78BFA),
        onPressed: () {
          setState(() {
            clearChoices();
            if (chance(55 + currentFloor * 3)) {
              tryUnlockRandomArt();
              textIt = 'Una Art casuale si apre.';
              textEn = 'A random Art opens.';
            } else {
              dungeonOculum += 1;
              textIt = '+1 Oculum run.';
              textEn = '+1 run Oculum.';
            }
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: '+EXP',
        labelEn: '+EXP',
        icon: Icons.note_alt,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            final exp = 60 + currentFloor * 12;
            gainDungeonExp(exp, forceLevelCheck: false);
            textIt = '+$exp EXP dungeon.';
            textEn = '+$exp dungeon EXP.';
          });
        },
      ),
    );
  }

  void quietCampEvent() {
    clearChoices();

    textIt =
        'Accampamento Quieto.\n\n'
        'Non è sicuro, ma per una volta non vuole morderti.';
    textEn =
        'Quiet Camp.\n\n'
        'It is not safe, but for once it does not want to bite you.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Cura e Scudo',
        labelEn: 'Heal and Shield',
        icon: Icons.nightlight,
        color: const Color(0xFFC4B5FD),
        onPressed: () {
          setState(() {
            clearChoices();
            final heal = 16 + currentFloor + totalOculum;
            final shield = 12 + currentFloor;
            playerHp = min(playerMaxHp, playerHp + heal);
            gainPlayerShield(shield);
            textIt = '+$heal HP\n+$shield Scudo.';
            textEn = '+$heal HP\n+$shield Shield.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Prepara zaino',
        labelEn: 'Prepare bag',
        icon: Icons.backpack,
        color: Colors.greenAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            addQuickPotion('minor', amount: 1);
            addQuickPotion('shield', amount: 1);
            textIt = '+1 Vitalium Grezzo\n+1 Fiala Scudo.';
            textEn = '+1 Raw Vitalium\n+1 Shield Vial.';
          });
        },
      ),
    );
  }

  void monsterVillageEvent() {
    clearChoices();

    final firstVillage = !unlockedTitleIds.contains('campione_primo_villaggio');
    grantFirstMonsterVillageRewards();
    fightsSinceTavernRest = 0;

    textIt =
        'Villaggio di mostri.\n\n'
        'Case basse, lanterne storte, denti gentili dietro le finestre.\n'
        'Qui non trovi corrotti: trovi scommesse, letti ruvidi, un fabbro e un mercante.\n\n'
        'Le lotte clandestine valgono come fight normali e danno molta esperienza, Obser e Ascension Dust.'
        '${firstVillage ? '\n\nPrimo villaggio: sblocchi Campione del Primo Villaggio, Combattimento a Mani Nude e Martial Art.' : ''}';
    textEn =
        'Monster village.\n\n'
        'Low houses, crooked lanterns, kind teeth behind the windows.\n'
        'You do not find corrupted here: you find bets, rough beds, a blacksmith and a merchant.\n\n'
        'Clandestine fights count as normal fights and grant a lot of EXP, Obser and Ascension Dust.'
        '${firstVillage ? '\n\nFirst village: you unlock Champion of the First Village, Bare-Hand Combat and Martial Arts.' : ''}';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Lotta clandestina',
        labelEn: 'Clandestine fight',
        icon: Icons.sports_martial_arts,
        color: const Color(0xFFFFD36A),
        onPressed: () => setState(startMonsterVillageClandestineFight),
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Dormi',
        labelEn: 'Sleep',
        icon: Icons.bed,
        color: const Color(0xFFC4B5FD),
        onPressed: monsterVillageSleep,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Mercante',
        labelEn: 'Merchant',
        icon: Icons.store,
        color: Colors.tealAccent,
        onPressed: openMonsterVillageMerchant,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Fabbro',
        labelEn: 'Blacksmith',
        icon: Icons.construction,
        color: Colors.orangeAccent,
        onPressed: openMonsterVillageBlacksmith,
      ),
    );
    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Riparti',
        labelEn: 'Leave',
        icon: Icons.exit_to_app,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt =
                'Lasci il villaggio. Le lanterne si spengono una alla volta.';
            textEn = 'You leave the village. The lanterns go out one by one.';
          });
        },
      ),
    );
  }

  MonsterBookEntry? monsterBookEntryForTemplate(_EnemyTemplate template) {
    for (final m in monsterBookEntries) {
      final mEn = m.nameEn.toLowerCase();
      final mIt = m.nameIt.toLowerCase();
      if (template.nameEn.toLowerCase().contains(mEn) ||
          template.nameIt.toLowerCase().contains(mIt) ||
          template.nameEn.toLowerCase().contains(m.id) ||
          template.nameIt.toLowerCase().contains(m.id)) {
        return m;
      }
    }
    return null;
  }

  _EnemyInstance createMonsterVillageFighter(int index, int count) {
    final pool = _enemies
        .where((e) => !e.boss)
        .where(
          (e) =>
              e.elementId != 'corrupted' &&
              e.elementId != 'oculum' &&
              e.elementId != 'nullum',
        )
        .toList();
    final template = pool.isEmpty
        ? chooseEnemyTemplate(boss: false)
        : pool[_random.nextInt(pool.length)];
    final matchedMonster = monsterBookEntryForTemplate(template);
    final factor = roomDifficultyFactor();
    final base = max(
      12,
      ((18 + currentFloor * 8 + runGrade * 5 + sheetPowerScore ~/ 38) * factor)
          .round(),
    );
    var hp = base + template.hpMod * 8 + currentFloor * 6;
    if (count > 1) hp = (hp * 0.72).round();
    final attack = max(
      3,
      (base / 4.2).round() + template.atkMod + currentFloor,
    ).toInt();
    final defense = max(
      0,
      (base / 9).round() + template.defMod + currentFloor ~/ 2,
    ).toInt();
    final suffixIt = count > 1 ? ' ${index + 1}' : '';
    final suffixEn = count > 1 ? ' ${index + 1}' : '';

    return _EnemyInstance(
      nameIt: 'Lottatore clandestino$suffixIt - ${template.nameIt}',
      nameEn: 'Clandestine Fighter$suffixEn - ${template.nameEn}',
      elementId: template.elementId,
      hp: hp,
      maxHp: hp,
      attack: attack,
      defense: defense,
      boss: false,
      elite: currentFloor >= 5 && chance(14),
      fetal:
          template.nameIt.contains('Fetale') ||
          template.nameEn.contains('Fetal'),
      level: max(1, currentFloor + runGrade),
      grade: runGrade,
      originalPower: enemyPowerScoreFromStats(hp, attack, defense),
      monsterId: matchedMonster?.id ?? 'monster_village_fighter',
      skillIds: matchedMonster?.skillIds,
      dropIds: matchedMonster?.dropIds,
      spriteAssetPath: matchedMonster?.spriteAssetPath,
    );
  }

  void startMonsterVillageClandestineFight() {
    clearChoices();
    monsterVillageFightActive = true;
    inCombat = true;
    enemyTurnPending = false;
    reactionAvailable = true;
    consecutivePlayerCritsThisFight = 0;
    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    valleyParticipatedInFight = valleyInFight;
    valleyBloomResolvedThisFight = false;

    final count = 1 + _random.nextInt(currentFloor >= 4 ? 3 : 2);
    enemyParty
      ..clear()
      ..addAll(
        List.generate(count, (i) => createMonsterVillageFighter(i, count)),
      );
    syncPrimaryEnemyFromParty();

    textIt =
        'Lotta clandestina.\n\n'
        'Il cerchio si chiude e i mostri battono i piedi.\n'
        'Regola del villaggio: se cadi, hai il 3% di probabilità di morire davvero.'
        '${hasMonsterVillageChampionTitle ? '\nTitolo attivo: rischio morte 0%.' : ''}\n\n'
        'Nemici: ${enemyPartySummary()}';
    textEn =
        'Clandestine fight.\n\n'
        'The circle closes and monsters stomp their feet.\n'
        'Village rule: if you fall, you have a 3% chance to truly die.'
        '${hasMonsterVillageChampionTitle ? '\nActive title: death risk 0%.' : ''}\n\n'
        'Enemies: ${enemyPartySummary()}';

    saveRunCheckpoint(
      reasonIt: 'Lotta clandestina registrata nel ricordo.',
      reasonEn: 'Clandestine fight recorded into memory.',
    );
  }

  void monsterVillageSleep() {
    setState(() {
      clearChoices();
      final restoredStats = restoreSpentRunStats(full: true);
      playerHp = playerMaxHp;
      oculumCharges = oculumMaxCharges;
      gainPlayerShield(10 + currentFloor * 2);
      restActionUsedThisRoom = true;
      fightsSinceTavernRest = 0;
      textIt =
          'Dormitorio del villaggio.\n\n'
          'Dormi tra coperte pesanti e russate non umane.\n'
          'Riposo lungo: HP pieni, Oculum pieno, Scudo +${10 + currentFloor * 2}.'
          '${spentStatsRestoreLineIt(restoredStats)}';
      textEn =
          'Village dormitory.\n\n'
          'You sleep among non-human snores and heavy blankets.\n'
          'Long rest: full HP, full Oculum, Shield +${10 + currentFloor * 2}.'
          '${spentStatsRestoreLineEn(restoredStats)}';
    });
  }

  void openMonsterVillageMerchant() {
    setState(() {
      merchantEvent();
      textIt = 'Mercante del villaggio.\n\n$textIt';
      textEn = 'Village merchant.\n\n$textEn';
    });
  }

  void openMonsterVillageBlacksmith() {
    setState(() {
      blacksmithEvent();
      textIt = 'Fabbro del villaggio.\n\n$textIt';
      textEn = 'Village blacksmith.\n\n$textEn';
    });
  }

  void drownedTradeCityEvent() {
    clearChoices();

    textIt =
        'Città della magia acquatica e degli affogati.\n\n'
        'Banchi bassi, gadget deboli, acqua tra i mattoni.\n'
        'Qui anche i piccoli oggetti sembrano Titoli Item.';
    textEn =
        'City of aquatic magic and the drowned.\n\n'
        'Low stalls, weak gadgets, water between the bricks.\n'
        'Here even small objects feel like Item Titles.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Compra gadget debole (7 Obser)',
        labelEn: 'Buy weak gadget (7 Obser)',
        icon: Icons.widgets,
        color: Colors.lightBlueAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            if (obserInRun < 7) {
              textIt = 'Non hai abbastanza Obser.';
              textEn = 'You do not have enough Obser.';
              return;
            }
            obserInRun -= 7;
            runDamageBonus += 1;
            runDefenseBonus += 1;
            textIt =
                'Gadget debole ottenuto.\n+1 danno run\n+1 difesa run.\n\nEffetti attivi: ${effectStateSummary()}';
            textEn =
                'Weak gadget obtained.\n+1 run damage\n+1 run defense.\n\nActive effects: ${effectStateSummary()}';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Impara necromanzia acquatica (3 Dust)',
        labelEn: 'Learn aquatic necromancy (3 Dust)',
        icon: Icons.water_drop,
        color: const Color(0xFF44A7FF),
        onPressed: () {
          setState(() {
            clearChoices();
            if (ascensionDustInRun < 3) {
              textIt = 'Ti servono 3 Ascension Dust.';
              textEn = 'You need 3 Ascension Dust.';
              return;
            }
            ascensionDustInRun -= 3;
            unlockedArtIds.add('water_necromancy_art');
            _savePermanentProgress();
            textIt =
                'Art di Necromanzia Acquatica sbloccata.\n'
                'Con 3 Oculum puoi tenere vivo un affogato per 3 turni.';
            textEn =
                'Aquatic Necromancy Art unlocked.\n'
                'With 3 Oculum you can keep a drowned creature alive for 3 turns.';
          });
        },
      ),
    );
  }

  void evonestTempleEvent() {
    clearChoices();

    textIt =
        'Tempio di Evonest.\n\n'
        'Un enorme rettile marino a tre teste respira nel buio.\n'
        'Dentro di lui parlano Dyro, Smarg e Leoness.\n'
        'Odia la corruzione e non crede al karma: vuole prove.';
    textEn =
        'Evonest Temple.\n\n'
        'A huge three-headed sea reptile breathes in the dark.\n'
        'Inside him speak Dyro, Smarg and Leoness.\n'
        'He hates corruption and does not trust karma: he wants proof.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Offri prova di bontà',
        labelEn: 'Offer proof of goodness',
        icon: Icons.volunteer_activism,
        color: Colors.tealAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            evonestProof++;
            playerHp = min(playerMaxHp, playerHp + 12 + totalOculum);
            if (evonestProof >= 1) {
              unlockedWeaponIds.add('evonest_three_head_scale');
              completeAchievement('evonest_proof');
              _savePermanentProgress();
            }
            textIt =
                'Evonest ascolta senza fidarsi del karma.\n'
                'La prova resta nel tempio.\n'
                '+HP e Scaglia di Evonest sbloccata.\n'
                'Se possiedi Frusta di Spine, la sua II può rispondere.';
            textEn =
                'Evonest listens without trusting karma.\n'
                'The proof remains in the temple.\n'
                '+HP and Evonest Scale unlocked.\n'
                'If you carry Thorn Whip, its II may answer.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Pronuncia Leoness',
        labelEn: 'Say Leoness',
        icon: Icons.favorite,
        color: const Color(0xFFD7B9FF),
        onPressed: () {
          setState(() {
            clearChoices();
            enemyWeak += 2;
            nextEnemyWeakened = true;
            gainOculumCharges(1);
            textIt =
                'Il nome di Leoness calma le tre teste.\n'
                '+1 carica Oculum\n'
                'Prossimo nemico indebolito.';
            textEn =
                'Leoness name calms the three heads.\n'
                '+1 Oculum charge\n'
                'Next enemy weakened.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Sfida la corruzione',
        labelEn: 'Challenge the corruption',
        icon: Icons.warning,
        color: Colors.redAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            spawnEnemy(elite: true);
            if (enemyParty.isNotEmpty) {
              final corrupted = enemyParty.first;
              corrupted.nameIt = 'Corruzione di Evonest';
              corrupted.nameEn = 'Evonest Corruption';
              corrupted.elementId = 'poison';
              corrupted.attack += 3 + currentFloor;
              corrupted.defense = max(0, corrupted.defense - 1).toInt();
              enemyWeak += 1;
              syncPrimaryEnemyFromParty();

              textIt +=
                  '\n\nLa corruzione prende forma: +attacco, elemento Veleno, ma +1 Debolezza.';
              textEn +=
                  '\n\nThe corruption takes shape: +attack, Poison element, but +1 Weakness.';
            }
          });
        },
      ),
    );
  }

  void asherFireEvent() {
    clearChoices();

    textIt =
        'Fuoco di Asher.\n\n'
        'La fiamma non chiede fede: chiede un contratto.\n'
        'Puoi pagare con stats, fondere un’Art o lasciarti osservare.';
    textEn =
        'Asher Fire.\n\n'
        'The flame does not ask for faith: it asks for a contract.\n'
        'You can pay with stats, fuse an Art or let it watch you.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Contratto fisico: -1 stat, critici bruciano',
        labelEn: 'Physical contract: -1 stat, crits burn',
        icon: Icons.local_fire_department,
        color: Colors.deepOrangeAccent,
        onPressed: () {
          setState(() {
            clearChoices();
            dungeonResilienza = max(-6, dungeonResilienza - 1);
            runCritBonus += 4;
            runBoons.add('asher_physical_burn');
            asherContractUses++;
            unlockedWeaponIds.add('asher_contract_brand');
            completeAchievement('asher_contract');
            textIt =
                'Contratto accettato.\n-1 Resilienza run\n+4 critico\nI critici possono bruciare.\n\nEffetti attivi: ${effectStateSummary()}';
            textEn =
                'Contract accepted.\n-1 run Resilience\n+4 critical\nCritical hits may burn.\n\nActive effects: ${effectStateSummary()}';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Contratto Art: -2 stats, Art fuoco +3 danni/livello',
        labelEn: 'Art contract: -2 stats, fire Art +3 damage/level',
        icon: Icons.whatshot,
        color: const Color(0xFFFF5A3C),
        onPressed: () {
          setState(() {
            clearChoices();
            dungeonVolonta = max(-6, dungeonVolonta - 1);
            dungeonMateria = max(-6, dungeonMateria - 1);
            runDamageBonus += max(3, (dungeonLevel + 1) * 3);
            unlockedArtIds.add('asher_fire_art');
            asherContractUses++;
            completeAchievement('asher_contract');
            _savePermanentProgress();
            textIt =
                'Fuoco di Asher fuso.\n-1 Volontà run\n-1 Materia run\n+3 danni per livello dungeon.';
            textEn =
                'Asher Fire fused.\n-1 run Will\n-1 run Materia\n+3 damage per dungeon level.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Lasciati osservare: +1 stat',
        labelEn: 'Let it watch: +1 stat',
        icon: Icons.visibility,
        color: const Color(0xFFFFD36A),
        onPressed: () {
          setState(() {
            clearChoices();
            dungeonOculum += 1;
            asherWatched = true;
            textIt =
                'Asher ti osserva.\n+1 Oculum run.\n\nEffetti attivi: ${effectStateSummary()}';
            textEn =
                'Asher watches you.\n+1 run Oculum.\n\nActive effects: ${effectStateSummary()}';
          });
        },
      ),
    );
  }

  void hideanAllianceEvent() {
    clearChoices();

    textIt =
        'Accordo Hideano.\n\n'
        'Gli Hideani sanno usare molte Art.\n'
        'Il loro capo porta l’Emblem Art dei Mille Fuochi grazie ad Asher.\n\n'
        'Questa Art appare solo nelle ultime 16 stanze dell’intera esperienza.';
    textEn =
        'Hidean Alliance.\n\n'
        'The Hideans can use many Arts.\n'
        'Their leader bears the Thousand Fires Emblem Art through Asher.\n\n'
        'This Art appears only in the last 16 rooms of the whole experience.';

    if (isInLastSixteenRooms) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Studia Mille Fuochi finale (gratis)',
          labelEn: 'Study Final Thousand Fires (free)',
          icon: Icons.local_fire_department,
          color: const Color(0xFFFF5A3C),
          onPressed: () {
            setState(() {
              clearChoices();
              if (runCount <= 1) {
                textIt =
                    'Mille Fuochi rifiuta la prima run.\n\n'
                    'Le braci hideane ti guardano, ma non ti riconoscono ancora.\n'
                    'Torna quando l’occhio avrà già ricordato almeno una tua caduta.';
                textEn =
                    'Thousand Fires refuses the first run.\n\n'
                    'The Hidean embers watch you, but do not recognize you yet.\n'
                    'Return when the eye has already remembered at least one of your falls.';
                return;
              }

              final milleFuochi = _allArts.firstWhere(
                (art) => art.effectId == 'thousand_fires_emblem_art',
              );
              activeArt = milleFuochi;
              completeAchievement('mille_fuochi_unlocked');
              textIt =
                  'Emblem Art dei Mille Fuochi risvegliata per questa run.\n\n'
                  'È una Art finale: fortissima, costo 0, cooldown 2 azioni.\n'
                  'Non entra negli sblocchi iniziali permanenti.';
              textEn =
                  'Thousand Fires Emblem Art awakened for this run.\n\n'
                  'It is a final Art: very strong, cost 0, 2-action cooldown.\n'
                  'It does not enter permanent starting unlocks.';
            });
          },
        ),
      );
    } else {
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Chiedi dei Mille Fuochi',
          labelEn: 'Ask about Thousand Fires',
          icon: Icons.info,
          color: const Color(0xFFFF5A3C),
          onPressed: () {
            setState(() {
              clearChoices();
              final missing = max(0, roomsRemainingInRun - 16);
              textIt =
                  'Gli Hideani scuotono la testa.\n\n'
                  'L’Emblem Art dei Mille Fuochi non si apre ancora.\n'
                  'Devi avvicinarti alla fine: mancano circa $missing stanze prima che possa apparire.';
              textEn =
                  'The Hideans shake their heads.\n\n'
                  'The Thousand Fires Emblem Art does not open yet.\n'
                  'You must approach the end: about $missing rooms remain before it can appear.';
            });
          },
        ),
      );
    }

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Compra gadget Hideano (9 Obser)',
        labelEn: 'Buy Hidean gadget (9 Obser)',
        icon: Icons.widgets,
        color: widget.tertiaryColor,
        onPressed: () {
          setState(() {
            clearChoices();
            if (obserInRun < 9) {
              textIt = 'Non hai abbastanza Obser.';
              textEn = 'You do not have enough Obser.';
              return;
            }
            obserInRun -= 9;
            runDamageBonus += 1;
            dungeonOculum += 1;
            textIt =
                'Gadget Hideano ottenuto.\n+1 danno run\n+1 Oculum run.\n\nEffetti attivi: ${effectStateSummary()}';
            textEn =
                'Hidean gadget obtained.\n+1 run damage\n+1 run Oculum.\n\nActive effects: ${effectStateSummary()}';
          });
        },
      ),
    );
  }

  void criticalShieldEvent() {
    clearChoices();

    textIt =
        'Scudo Critico.\n\n'
        'Una lastra d’occhio spezzato ti gira attorno.\n'
        'Finché non subisci un colpo critico, divide i danni in arrivo.';
    textEn =
        'Critical Shield.\n\n'
        'A slab of broken eye circles around you.\n'
        'Until you suffer a critical hit, it divides incoming damage.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Accetta lo Scudo Critico',
        labelEn: 'Accept Critical Shield',
        icon: Icons.shield_moon,
        color: const Color(0xFFFFD36A),
        onPressed: () {
          setState(() {
            clearChoices();
            criticalShieldActive = true;
            criticalShieldBlocks = 0;
            gainPlayerShield(12 + currentFloor * 2);

            textIt =
                'Scudo Critico attivo.\n'
                'I danni subiti vengono divisi finché un nemico non ti colpisce criticamente.\n'
                '+${12 + currentFloor * 2} Scudo.';
            textEn =
                'Critical Shield active.\n'
                'Incoming damage is divided until an enemy critically hits you.\n'
                '+${12 + currentFloor * 2} Shield.';
          });
        },
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Rifiuta',
        labelEn: 'Refuse',
        icon: Icons.close,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt = 'Rifiuti lo Scudo Critico. L’occhio spezzato si chiude.';
            textEn = 'You refuse the Critical Shield. The broken eye closes.';
          });
        },
      ),
    );
  }

  void merchantEvent() {
    clearChoices();
    if (merchantActionUsedThisRoom) {
      textIt =
          'Il Mercante della Piuma Indaco richiude il mantello. Una sola scelta per visita.';
      textEn =
          'The Indigo Feather Merchant closes his cloak. One choice per visit.';
      return;
    }
    final pool = currentShopPool()..shuffle(_random);
    final offers = pool.take(4).toList();

    textIt = 'Mercante della Piuma Indaco.\nScegli cosa comprare.';
    textEn = 'Indigo Feather Merchant.\nChoose what to buy.';

    if (sparklingGears > 0 && !merchantGearsSoldThisRoom) {
      eventChoices.add(
        _DungeonChoice(
          labelIt:
              'Vendi $sparklingGears Ingranaggi Scintillanti (+${sparklingGears * 3} Obser)',
          labelEn:
              'Sell $sparklingGears Glimmering Gears (+${sparklingGears * 3} Obser)',
          icon: Icons.auto_awesome,
          color: const Color(0xFFFFD36A),
          onPressed: sellSparklingGearsToMerchant,
        ),
      );
    }

    for (final item in offers) {
      eventChoices.add(
        _DungeonChoice(
          labelIt:
              '${item.nameIt} (${tavernDiscountedObserCost(item.costObser)}O/${tavernDiscountedDustCost(item.costDust)}D)',
          labelEn:
              '${item.nameEn} (${tavernDiscountedObserCost(item.costObser)}O/${tavernDiscountedDustCost(item.costDust)}D)',
          icon: Icons.shopping_bag,
          color: item.elementId == 'neutral'
              ? widget.tertiaryColor
              : elementColor(item.elementId),
          onPressed: () => buyMerchantItem(item),
        ),
      );
    }
  }

  void sellSparklingGearsToMerchant() {
    setState(() {
      if (merchantGearsSoldThisRoom) {
        textIt = 'Hai già venduto gli Ingranaggi in questa visita.';
        textEn = 'You already sold the Gears during this visit.';
        return;
      }

      if (sparklingGears <= 0) {
        textIt = 'Non hai Ingranaggi Scintillanti da vendere.';
        textEn = 'You have no Glimmering Gears to sell.';
        return;
      }

      final sold = sparklingGears;
      final gained = sold * 3;
      sparklingGears = 0;
      obserInRun += gained;
      merchantGearsSoldThisRoom = true;

      merchantEvent();

      textIt =
          'Kooba abbassa le orecchie, poi annuisce: erano oggetti abbandonati.\n\n'
          'Hai venduto $sold Ingranaggi Scintillanti.\n'
          '+$gained Obser.\n\n'
          '$textIt';
      textEn =
          'Kooba lowers its ears, then nods: they were abandoned objects.\n\n'
          'You sold $sold Glimmering Gears.\n'
          '+$gained Obser.\n\n'
          '$textEn';
    });
  }

  List<_ShopItem> currentShopPool() {
    if (runCount <= 3) {
      return _shopItems.where((i) => i.firstThreeRunsOnly).toList();
    }
    return List<_ShopItem>.from(_shopItems);
  }

  void buyMerchantItem(_ShopItem item) {
    setState(() {
      final costObser = tavernDiscountedObserCost(item.costObser);
      final costDust = tavernDiscountedDustCost(item.costDust);

      if (obserInRun < costObser || ascensionDustInRun < costDust) {
        textIt = 'Non hai abbastanza risorse.';
        textEn = 'You do not have enough resources.';
        return;
      }

      obserInRun -= costObser;
      ascensionDustInRun -= costDust;
      merchantActionUsedThisRoom = true;
      clearChoices();
      purchasedRelics.add(widget.linguaInglese ? item.nameEn : item.nameIt);
      merchantBuys++;
      checkPassiveAchievements();

      switch (item.effectId) {
        case 'heal_18':
          playerHp = min(playerMaxHp, playerHp + 18);
          break;
        case 'map':
          mapRevealed = true;
          break;
        case 'dodge_defense':
          dodgeCharges += 1;
          runDefenseBonus += 1;
          break;
        case 'second_chance':
          moonSecondChance = true;
          break;
        case 'oculum_charge_1':
          gainOculumCharges(1);
          break;
        case 'unlock_cm_attack':
          if (!runBoons.contains('unlock_cm_attack')) {
            runBoons.add('unlock_cm_attack');
          }
          break;
        case 'unlock_aoe_vc':
          if (!runBoons.contains('unlock_aoe_vc')) {
            runBoons.add('unlock_aoe_vc');
          }
          break;
        case 'unlock_aoe_cm':
          if (!runBoons.contains('unlock_aoe_cm')) {
            runBoons.add('unlock_aoe_cm');
          }
          break;
        case 'scroll_double_breath':
          occultScrollsFound++;
          if (!runBoons.contains('scroll_double_breath')) {
            runBoons.add('scroll_double_breath');
          }
          runCritBonus += 2;
          break;
        case 'scroll_bouncing_eye':
          occultScrollsFound++;
          if (!runBoons.contains('scroll_bouncing_eye')) {
            runBoons.add('scroll_bouncing_eye');
          }
          break;

        case 'potion_minor':
          addQuickPotion('minor', amount: 1);
          break;
        case 'potion_major':
          addQuickPotion('major', amount: 1);
          break;
        case 'potion_shield':
          addQuickPotion('shield', amount: 1);
          break;
        case 'potion_oculum':
          addQuickPotion('oculum', amount: 1);
          break;
        case 'potion_cleanse':
          addQuickPotion('cleanse', amount: 1);
          break;
        case 'potion_smoke':
          addQuickPotion('smoke', amount: 1);
          break;
        case 'unlock_random_weapon':
          tryUnlockRandomWeapon();
          break;
        case 'unlock_random_npc':
          unlockRandomGoodNpc();
          break;
        case 'trade_gadget_weak':
          runDamageBonus += 1;
          runDefenseBonus += 1;
          break;
        case 'trade_gadget_drowned':
          dungeonOculum += 2;
          runDefenseBonus += 1;
          break;
        case 'resist':
          elementalResist[item.elementId] =
              (elementalResist[item.elementId] ?? 0) + item.resist;
          break;
        case 'resist_damage':
          elementalResist[item.elementId] =
              (elementalResist[item.elementId] ?? 0) + item.resist;
          runDamageBonus += 1;
          break;
        case 'relic_resist':
          elementalResist[item.elementId] =
              (elementalResist[item.elementId] ?? 0) + item.resist;
          runDefenseBonus += 2;
          dungeonOculum += 2;
          break;
      }

      textIt = 'Comprato: ${item.nameIt}\n\n${item.descIt}';
      textEn = 'Bought: ${item.nameEn}\n\n${item.descEn}';
    });
  }

  bool get hasSkellyUnlocked {
    return unlockedNpcIds.contains('skelly_bone_innkeeper') ||
        activeAllies.any((npc) => npc.id == 'skelly_bone_innkeeper');
  }

  bool get isSkellyInParty =>
      activeAllies.any((npc) => npc.id == 'skelly_bone_innkeeper');

  int tavernDiscountedObserCost(int baseCost) {
    if (!hasTavernkeeperEquipped) return baseCost;
    return max(0, (baseCost * 0.75).floor());
  }

  int tavernDiscountedDustCost(int baseCost) {
    if (!hasTavernkeeperEquipped) return baseCost;
    return max(0, (baseCost * 0.80).floor());
  }

  int get tavernMealCost =>
      hasTavernkeeperEquipped ? 0 : tavernDiscountedObserCost(6);

  int get tavernSleepCost => tavernDiscountedObserCost(10);

  int get tavernFullOculumCharges =>
      max(3, 3 + totalOculum + dungeonLevel ~/ 2);

  void tavernEvent() {
    clearChoices();

    final skellyLine = hasSkellyUnlocked
        ? '\n\nSkelly sbuca da dietro esultando:\n“che dolce mortalità!”'
        : '';

    if (hasTavernkeeperEquipped) {
      textIt =
          'Taverna del Teschio Enorme.\n\n'
          'Il Taverniere è con te.\n'
          'L’enorme cranio scheletrico si mette dietro il bancone e appoggia le mani d’ossa sul legno.\n\n'
          'Con lui nel party non puoi rifiutare la taverna.\n'
          'Il pasto sarà gratis e gli sconti restano attivi.'
          '$skellyLine';
      textEn =
          'Giant Skull Tavern.\n\n'
          'The Tavernkeeper is with you.\n'
          'The enormous skeletal skull moves behind the counter and rests its bone hands on the wood.\n\n'
          'With him in the party, you cannot refuse the tavern.\n'
          'The meal will be free and discounts stay active.'
          '$skellyLine';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Vai al bancone',
          labelEn: 'Go to the counter',
          icon: Icons.local_bar,
          color: const Color(0xFFE8E2FF),
          onPressed: showTavernHub,
        ),
      );
      return;
    }

    textIt =
        'Taverna del Teschio Enorme.\n\n'
        'Un cranio gigantesco apre la mandibola come una porta.\n'
        'Dentro senti dadi d’ossa, pane duro e canzoni stonate.'
        '$skellyLine\n\n'
        'Vuoi entrare?';
    textEn =
        'Giant Skull Tavern.\n\n'
        'A gigantic skull opens its jaw like a door.\n'
        'Inside you hear bone dice, hard bread and crooked songs.'
        '$skellyLine\n\n'
        'Do you want to enter?';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Entra',
        labelEn: 'Enter',
        icon: Icons.local_bar,
        color: const Color(0xFFE8E2FF),
        onPressed: showTavernHub,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Vattene via',
        labelEn: 'Go away',
        icon: Icons.exit_to_app,
        color: Colors.blueGrey,
        onPressed: tavernLeaveLine,
      ),
    );
  }

  void tavernLeaveLine() {
    setState(() {
      clearChoices();

      if (isSkellyInParty) {
        textIt =
            'Skelly abbassa lo sguardo:\n'
            '"Peccato... niente taverna, capo."\n\n'
            'Ti allontani dal Teschio Enorme insieme al party.';
        textEn =
            'Skelly lowers his gaze:\n'
            '"Too bad... no tavern, chief."\n\n'
            'You walk away from the Giant Skull with your party.';
      } else {
        textIt =
            'Ti fermi un momento davanti al Teschio Enorme,\n'
            'poi scegli di non entrare e prosegui.';
        textEn =
            'You pause for a moment in front of the Giant Skull,\n'
            'then choose not to enter and move on.';
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Entra comunque',
          labelEn: 'Enter anyway',
          icon: Icons.local_bar,
          color: const Color(0xFFE8E2FF),
          onPressed: showTavernHub,
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Andartene',
          labelEn: 'Leave',
          icon: Icons.exit_to_app,
          color: Colors.blueGrey,
          onPressed: () {
            setState(() {
              clearChoices();
              textIt = 'Ti allontani dal Teschio Enorme.';
              textEn = 'You walk away from the Giant Skull.';
            });
          },
        ),
      );
    });
  }

  void showTavernHub() {
    setState(() {
      buildTavernHub();
    });
  }

  void buildTavernHub() {
    clearChoices();

    final mealLine = tavernMealUsedThisRoom
        ? t('Pasto già servito.', 'Meal already served.')
        : hasTavernkeeperEquipped
        ? t(
            'Il Taverniere ti serve il pasto gratis.',
            'The Tavernkeeper serves your meal for free.',
          )
        : t(
            'Pasto disponibile: $tavernMealCost Obser.',
            'Meal available: $tavernMealCost Obser.',
          );

    textIt =
        'Bancone del Teschio Enorme.\n\n'
        '$mealLine\n\n'
        'Ordine della taverna:\n'
        '1. Pasto.\n'
        '2. Mercante e/o Fabbro, una azione ciascuno.\n'
        '3. Dormire spendendo Obser oppure andartene.';
    textEn =
        'Giant Skull Counter.\n\n'
        '$mealLine\n\n'
        'Tavern order:\n'
        '1. Meal.\n'
        '2. Merchant and/or Blacksmith, one action each.\n'
        '3. Sleep by spending Obser, or leave.';

    if (!tavernMealUsedThisRoom) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: hasTavernkeeperEquipped
              ? 'Pasto gratis'
              : 'Compra pasto ($tavernMealCost Obser)',
          labelEn: hasTavernkeeperEquipped
              ? 'Free meal'
              : 'Buy meal ($tavernMealCost Obser)',
          icon: Icons.restaurant,
          color: Colors.orangeAccent,
          onPressed: tavernTakeMeal,
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Cerca qualcuno nella taverna',
          labelEn: 'Look for someone in the tavern',
          icon: Icons.groups,
          color: const Color(0xFFE8E2FF),
          onPressed: rollGiantSkullTavern,
        ),
      );

      if (!hasTavernkeeperEquipped) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Andartene',
            labelEn: 'Leave',
            icon: Icons.exit_to_app,
            color: Colors.blueGrey,
            onPressed: tavernExit,
          ),
        );
      }

      return;
    }

    if (!tavernMerchantActionUsedThisRoom) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Vai dal mercante',
          labelEn: 'Go to the merchant',
          icon: Icons.store,
          color: widget.tertiaryColor,
          onPressed: tavernMerchantService,
        ),
      );
    }

    if (!tavernBlacksmithActionUsedThisRoom) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Vai dal fabbro',
          labelEn: 'Go to the blacksmith',
          icon: Icons.build,
          color: const Color(0xFFA98BFF),
          onPressed: tavernBlacksmithService,
        ),
      );
    }

    if (!tavernSleepUsedThisRoom) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Dormi: Oculum pieno + metà vita ($tavernSleepCost Obser)',
          labelEn: 'Sleep: full Oculum + half HP ($tavernSleepCost Obser)',
          icon: Icons.visibility,
          color: const Color(0xFF8B5CF6),
          onPressed: () => tavernSleep(oculumFocused: true),
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Dormi: vita piena + metà Oculum ($tavernSleepCost Obser)',
          labelEn: 'Sleep: full HP + half Oculum ($tavernSleepCost Obser)',
          icon: Icons.hotel,
          color: const Color(0xFFC4B5FD),
          onPressed: () => tavernSleep(oculumFocused: false),
        ),
      );
    }

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Andartene',
        labelEn: 'Leave',
        icon: Icons.exit_to_app,
        color: Colors.blueGrey,
        onPressed: tavernExit,
      ),
    );
  }

  void tavernTakeMeal() {
    setState(() {
      clearChoices();

      final cost = tavernMealCost;
      if (tavernMealUsedThisRoom) {
        buildTavernHub();
        return;
      }

      if (cost > 0 && obserInRun < cost) {
        textIt = 'Non hai abbastanza Obser per il pasto.';
        textEn = 'You do not have enough Obser for the meal.';
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Torna al bancone',
            labelEn: 'Back to counter',
            icon: Icons.keyboard_return,
            color: widget.tertiaryColor,
            onPressed: showTavernHub,
          ),
        );
        return;
      }

      if (cost > 0) obserInRun -= cost;

      final heal = 18 + currentFloor + totalOculum;
      final mealRegen = hasTavernkeeperEquipped ? 2 : 1;

      playerHp = min(playerMaxHp, playerHp + heal);
      runHealOnExplore += mealRegen;
      tavernMealUsedThisRoom = true;
      fightsSinceTavernRest = 0;

      textIt = hasTavernkeeperEquipped
          ? 'Il Taverniere ti serve il pasto gratis.\n+$heal HP\n+$mealRegen cura a ogni esplorazione.'
          : 'Paghi $cost Obser e mangi un pasto caldo.\n+$heal HP\n+$mealRegen cura a ogni esplorazione.';
      textEn = hasTavernkeeperEquipped
          ? 'The Tavernkeeper serves your meal for free.\n+$heal HP\n+$mealRegen healing on each exploration.'
          : 'You pay $cost Obser and eat a warm meal.\n+$heal HP\n+$mealRegen healing on each exploration.';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Procedi',
          labelEn: 'Proceed',
          icon: Icons.arrow_forward,
          color: widget.tertiaryColor,
          onPressed: showTavernHub,
        ),
      );
    });
  }

  void tavernMerchantService() {
    setState(() {
      clearChoices();

      if (tavernMerchantActionUsedThisRoom) {
        buildTavernHub();
        return;
      }

      textIt =
          'Mercante della taverna.\n\n'
          'Puoi fare una sola azione mercante in questa taverna.';
      textEn =
          'Tavern merchant.\n\n'
          'You can take only one merchant action in this tavern.';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Compra Vitalium Grezzo (${tavernDiscountedObserCost(5)}O)',
          labelEn: 'Buy Raw Vitalium (${tavernDiscountedObserCost(5)}O)',
          icon: Icons.local_hospital,
          color: Colors.greenAccent,
          onPressed: () =>
              tavernBuyConsumable('minor', tavernDiscountedObserCost(5), 0),
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Compra Fiala Oculum (${tavernDiscountedObserCost(10)}O/1D)',
          labelEn: 'Buy Oculum Vial (${tavernDiscountedObserCost(10)}O/1D)',
          icon: Icons.visibility,
          color: const Color(0xFF8B5CF6),
          onPressed: () =>
              tavernBuyConsumable('oculum', tavernDiscountedObserCost(10), 1),
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Compra Fumo Fuga (${tavernDiscountedObserCost(12)}O)',
          labelEn: 'Buy Escape Smoke (${tavernDiscountedObserCost(12)}O)',
          icon: Icons.smoke_free,
          color: Colors.blueGrey,
          onPressed: () =>
              tavernBuyConsumable('smoke', tavernDiscountedObserCost(12), 0),
        ),
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Rinuncia al mercante',
          labelEn: 'Skip merchant',
          icon: Icons.close,
          color: Colors.blueGrey,
          onPressed: () {
            setState(() {
              tavernMerchantActionUsedThisRoom = true;
              buildTavernHub();
            });
          },
        ),
      );
    });
  }

  void tavernBuyConsumable(String type, int costObser, int costDust) {
    setState(() {
      clearChoices();

      if (tavernMerchantActionUsedThisRoom) {
        buildTavernHub();
        return;
      }

      if (obserInRun < costObser || ascensionDustInRun < costDust) {
        textIt = 'Non hai abbastanza risorse.';
        textEn = 'You do not have enough resources.';
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Torna al mercante',
            labelEn: 'Back to merchant',
            icon: Icons.keyboard_return,
            color: widget.tertiaryColor,
            onPressed: tavernMerchantService,
          ),
        );
        return;
      }

      obserInRun -= costObser;
      ascensionDustInRun -= costDust;
      addQuickPotion(type, amount: 1);
      tavernMerchantActionUsedThisRoom = true;
      merchantBuys++;
      checkPassiveAchievements();

      textIt =
          'Acquisto completato.\n'
          'Zaino rapido: ${quickInventorySummary()}\n\n'
          'Effetti attivi: ${effectStateSummary()}';
      textEn =
          'Purchase completed.\n'
          'Quick bag: ${quickInventorySummary()}\n\n'
          'Active effects: ${effectStateSummary()}';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Torna al bancone',
          labelEn: 'Back to counter',
          icon: Icons.keyboard_return,
          color: widget.tertiaryColor,
          onPressed: showTavernHub,
        ),
      );
    });
  }

  void tavernBlacksmithService() {
    setState(() {
      clearChoices();

      if (tavernBlacksmithActionUsedThisRoom) {
        buildTavernHub();
        return;
      }

      textIt =
          'Fabbro della taverna.\n\n'
          'Puoi fare una sola azione fabbro in questa taverna.';
      textEn =
          'Tavern blacksmith.\n\n'
          'You can take only one blacksmith action in this tavern.';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Ritocca arma (${tavernDiscountedObserCost(7)}O/1D)',
          labelEn: 'Tune weapon (${tavernDiscountedObserCost(7)}O/1D)',
          icon: Icons.build,
          color: const Color(0xFFA98BFF),
          onPressed: tavernTuneWeapon,
        ),
      );

      if (inventoryDrops.isNotEmpty) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Frantuma drop nell’arma',
            labelEn: 'Grind drop into weapon',
            icon: Icons.diamond,
            color: Colors.amber,
            onPressed: tavernFreeDropGrind,
          ),
        );
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Rinuncia al fabbro',
          labelEn: 'Skip blacksmith',
          icon: Icons.close,
          color: Colors.blueGrey,
          onPressed: () {
            setState(() {
              tavernBlacksmithActionUsedThisRoom = true;
              buildTavernHub();
            });
          },
        ),
      );
    });
  }

  void tavernTuneWeapon() {
    setState(() {
      clearChoices();

      if (tavernBlacksmithActionUsedThisRoom) {
        buildTavernHub();
        return;
      }

      final costObser = tavernDiscountedObserCost(7);
      const costDust = 1;

      if (obserInRun < costObser || ascensionDustInRun < costDust) {
        textIt = 'Non hai abbastanza risorse per il fabbro.';
        textEn = 'You do not have enough resources for the blacksmith.';
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Torna al fabbro',
            labelEn: 'Back to blacksmith',
            icon: Icons.keyboard_return,
            color: widget.tertiaryColor,
            onPressed: tavernBlacksmithService,
          ),
        );
        return;
      }

      obserInRun -= costObser;
      ascensionDustInRun -= costDust;
      tavernBlacksmithActionUsedThisRoom = true;
      final damageGain = 1 + blacksmithFavor ~/ 5;
      final defenseGain = currentFloor >= 6 ? 1 : 0;

      attachedDamageBonus += damageGain;
      attachedDefenseBonus += defenseGain;
      blacksmithFavor += 1;

      textIt =
          'Il fabbro ritocca l’arma.\n'
          '+$damageGain danni arma\n'
          '${defenseGain > 0 ? '+$defenseGain difesa arma\n' : ''}'
          '+1 favore fabbro.\n\n'
          'Effetti attivi: ${effectStateSummary()}';
      textEn =
          'The blacksmith tunes the weapon.\n'
          '+$damageGain weapon damage\n'
          '${defenseGain > 0 ? '+$defenseGain weapon defense\n' : ''}'
          '+1 blacksmith favor.\n\n'
          'Active effects: ${effectStateSummary()}';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Torna al bancone',
          labelEn: 'Back to counter',
          icon: Icons.keyboard_return,
          color: widget.tertiaryColor,
          onPressed: showTavernHub,
        ),
      );
    });
  }

  void tavernFreeDropGrind() {
    setState(() {
      clearChoices();

      if (tavernBlacksmithActionUsedThisRoom) {
        buildTavernHub();
        return;
      }

      if (inventoryDrops.isEmpty) {
        buildTavernHub();
        return;
      }

      final drop = inventoryDrops.removeAt(0);

      final dust = max(1, drop.sellDust ~/ 2 + drop.resistBonus ~/ 4);
      final damageGain = max(1, drop.damageBonus);
      final defenseGain = max(0, drop.defenseBonus);
      final resistGain = max(1, drop.resistBonus ~/ 2);

      ascensionDustInRun += dust;
      attachedDamageBonus += damageGain;
      attachedDefenseBonus += defenseGain;
      elementalResist[drop.elementId] =
          (elementalResist[drop.elementId] ?? 0) + resistGain;
      blacksmithFavor += 1;
      tavernBlacksmithActionUsedThisRoom = true;

      textIt =
          'Il fabbro frantuma il drop dentro l’arma:\n'
          '${drop.nameIt}\n\n'
          'La proprietà di ${elementName(drop.elementId)} entra nel metallo.\n\n'
          '+$damageGain danni arma\n'
          '+$defenseGain difesa arma\n'
          '+$resistGain resistenza ${elementName(drop.elementId)}\n'
          '+$dust Ascension Dust\n'
          '+1 favore fabbro.\n\n'
          'Effetti attivi: ${effectStateSummary()}';
      textEn =
          'The blacksmith grinds the drop into the weapon:\n'
          '${drop.nameEn}\n\n'
          'The ${elementName(drop.elementId)} property enters the metal.\n\n'
          '+$damageGain weapon damage\n'
          '+$defenseGain weapon defense\n'
          '+$resistGain ${elementName(drop.elementId)} resistance\n'
          '+$dust Ascension Dust\n'
          '+1 blacksmith favor.\n\n'
          'Active effects: ${effectStateSummary()}';

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Torna al bancone',
          labelEn: 'Back to counter',
          icon: Icons.keyboard_return,
          color: widget.tertiaryColor,
          onPressed: showTavernHub,
        ),
      );
    });
  }

  void tavernSleep({required bool oculumFocused}) {
    setState(() {
      clearChoices();

      if (tavernSleepUsedThisRoom) {
        buildTavernHub();
        return;
      }

      final cost = tavernSleepCost;
      if (obserInRun < cost) {
        textIt = 'Non hai abbastanza Obser per dormire.';
        textEn = 'You do not have enough Obser to sleep.';
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Torna al bancone',
            labelEn: 'Back to counter',
            icon: Icons.keyboard_return,
            color: widget.tertiaryColor,
            onPressed: showTavernHub,
          ),
        );
        return;
      }

      obserInRun -= cost;
      tavernSleepUsedThisRoom = true;
      restActionUsedThisRoom = true;
      fightsSinceTavernRest = 0;
      completeAchievement('tavern_sleep');
      final restoredStats = restoreSpentRunStats(full: true);

      final fullCharges = tavernFullOculumCharges;
      final halfCharges = max(1, fullCharges ~/ 2);
      final halfHp = max(1, playerMaxHp ~/ 2);

      if (oculumFocused) {
        oculumCharges = max(oculumCharges, fullCharges);
        playerHp = max(playerHp, halfHp);
        textIt =
            'Dormi concentrandoti sull’Oculum.\n'
            'Cariche Oculum piene: $oculumCharges\n'
            'Vita portata almeno a metà: $playerHp/$playerMaxHp.\n\n'
            'Effetti attivi: ${effectStateSummary()}';
        textEn =
            'You sleep focusing on Oculum.\n'
            'Full Oculum charges: $oculumCharges\n'
            'HP raised at least to half: $playerHp/$playerMaxHp.\n\n'
            'Active effects: ${effectStateSummary()}';
        textIt += spentStatsRestoreLineIt(restoredStats);
        textEn += spentStatsRestoreLineEn(restoredStats);
      } else {
        playerHp = playerMaxHp;
        oculumCharges = max(oculumCharges, halfCharges);
        textIt =
            'Dormi concentrandoti sul corpo.\n'
            'Vita piena: $playerHp/$playerMaxHp\n'
            'Cariche Oculum portate almeno a metà: $oculumCharges.\n\n'
            'Effetti attivi: ${effectStateSummary()}';
        textEn =
            'You sleep focusing on the body.\n'
            'Full HP: $playerHp/$playerMaxHp\n'
            'Oculum charges raised at least to half: $oculumCharges.\n\n'
            'Active effects: ${effectStateSummary()}';
        textIt += spentStatsRestoreLineIt(restoredStats);
        textEn += spentStatsRestoreLineEn(restoredStats);
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Andartene',
          labelEn: 'Leave',
          icon: Icons.exit_to_app,
          color: Colors.blueGrey,
          onPressed: tavernExit,
        ),
      );
    });
  }

  void tavernExit() {
    setState(() {
      clearChoices();
      textIt = 'Lasci la Taverna del Teschio Enorme.';
      textEn = 'You leave the Giant Skull Tavern.';
    });
  }

  void rollGiantSkullTavern() {
    setState(() {
      clearChoices();

      final roll = _random.nextInt(100) + 1;
      late _GoodNpc npc;
      String rarityIt;
      String rarityEn;
      bool alreadyKnown = false;

      if (roll <= 96) {
        npc = npcById('skelly_bone_innkeeper')!;
        rarityIt = '96% — Skelly';
        rarityEn = '96% — Skelly';

        if (hasSkellyUnlocked) {
          alreadyKnown = true;
        }
      } else if (roll <= 99) {
        npc = npcById('skelly_evolved')!;
        rarityIt = '3% — Skelly Evoluto';
        rarityEn = '3% — Evolved Skelly';

        if (unlockedNpcIds.contains(npc.id)) {
          alreadyKnown = true;
        }
      } else {
        npc = npcById('giant_skull_tavernkeeper')!;
        rarityIt = '1% — Il Taverniere';
        rarityEn = '1% — The Tavernkeeper';

        if (unlockedNpcIds.contains(npc.id)) {
          alreadyKnown = true;
        }
      }

      if (alreadyKnown) {
        final heal = npc.id == 'skelly_bone_innkeeper'
            ? 8 + currentFloor
            : 12 + currentFloor;
        playerHp = min(playerMaxHp, playerHp + heal);

        textIt =
            'Incontro nella Taverna del Teschio Enorme.\n\n'
            '$rarityIt\n'
            '${npc.nameIt}\n\n'
            'Lo conosci già. Non viene sbloccato una seconda volta.\n'
            '${npc.id == 'skelly_bone_innkeeper' ? 'Skelly dice: “oh, morte dolce morte!”\n' : ''}'
            '+$heal HP.';
        textEn =
            'Encounter in the Giant Skull Tavern.\n\n'
            '$rarityEn\n'
            '${npc.nameEn}\n\n'
            'You already know them. They are not unlocked a second time.\n'
            '${npc.id == 'skelly_bone_innkeeper' ? 'Skelly says: “oh, sweet death sweet death!”\n' : ''}'
            '+$heal HP.';
      } else {
        unlockedNpcIds.add(npc.id);
        _savePermanentProgress();

        textIt =
            'Incontro nella Taverna del Teschio Enorme.\n\n'
            '$rarityIt\n'
            '${npc.nameIt}\n\n'
            '${npc.descIt}\n\n'
            '${npc.id == 'giant_skull_tavernkeeper' ? 'È un enorme cranio scheletrico con mani scheletriche troppo lunghe, inquietante come qualcosa scavato sotto una miniera viva.\n\n' : ''}'
            'NPC sbloccato. Ora puoi portarlo dal tasto Alleati.';
        textEn =
            'Encounter in the Giant Skull Tavern.\n\n'
            '$rarityEn\n'
            '${npc.nameEn}\n\n'
            '${npc.descEn}\n\n'
            '${npc.id == 'giant_skull_tavernkeeper' ? 'It is an enormous skeletal skull with skeletal hands that are too long, unsettling like something dug beneath a living mine.\n\n' : ''}'
            'NPC unlocked. You can now bring them from the Allies button.';

        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Portalo nel party',
            labelEn: 'Bring to party',
            icon: Icons.person_add,
            color: elementColor(npc.elementId),
            onPressed: () => toggleAlly(npc),
          ),
        );
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Torna al bancone',
          labelEn: 'Back to counter',
          icon: Icons.keyboard_return,
          color: widget.tertiaryColor,
          onPressed: showTavernHub,
        ),
      );
    });
  }

  void blacksmithEvent() {
    clearChoices();
    if (blacksmithActionUsedThisRoom) {
      textIt =
          'Il Fabbro del Vapium Muto ha già lavorato. Le sue dita restano immobili.';
      textEn =
          'The Mute Vapium Blacksmith has already worked. His fingers stay still.';
      return;
    }
    textIt =
        'Fabbro del Vapium Muto.\n\n'
        'Può riforgiare la tua arma o lavorare i drop unici.\n'
        'Primo reforge della run: gratis.';
    textEn =
        'Mute Vapium Blacksmith.\n\n'
        'He can reforge your weapon or work unique drops.\n'
        'First reforge of the run: free.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: freeReforges > 0
            ? 'Reforge gratis'
            : 'Reforge (${tavernDiscountedObserCost(8)}O/${tavernDiscountedDustCost(2)}D)',
        labelEn: freeReforges > 0
            ? 'Free reforge'
            : 'Reforge (${tavernDiscountedObserCost(8)}O/${tavernDiscountedDustCost(2)}D)',
        icon: Icons.build,
        color: widget.tertiaryColor,
        onPressed: reforgeWeapon,
      ),
    );

    if (inventoryDrops.isNotEmpty) {
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Gestisci drop unici',
          labelEn: 'Manage unique drops',
          icon: Icons.diamond,
          color: const Color(0xFFA98BFF),
          onPressed: showDropManagement,
        ),
      );
    }
  }

  void reforgeWeapon() {
    setState(() {
      if (freeReforges > 0) {
        freeReforges--;
      } else {
        final costObser = tavernDiscountedObserCost(8);
        final costDust = tavernDiscountedDustCost(2);

        if (obserInRun < costObser || ascensionDustInRun < costDust) {
          textIt = 'Il fabbro indica le tue tasche vuote.';
          textEn = 'The blacksmith points at your empty pockets.';
          return;
        }
        obserInRun -= costObser;
        ascensionDustInRun -= costDust;
      }

      blacksmithActionUsedThisRoom = true;
      clearChoices();
      reforgeCount++;
      final gainDmg = 1 + reforgeCount ~/ 3 + blacksmithFavor ~/ 4;
      final gainDef = reforgeCount % 2 == 0 ? 1 : 0;
      attachedDamageBonus += gainDmg;
      attachedDefenseBonus += gainDef;

      textIt =
          'Reforge completato.\n'
          '+$gainDmg danni arma\n'
          '+$gainDef difesa arma\n'
          'Reforge totali: $reforgeCount';
      textEn =
          'Reforge completed.\n'
          '+$gainDmg weapon damage\n'
          '+$gainDef weapon defense\n'
          'Total reforges: $reforgeCount';
    });
  }

  String effectStateSummary() {
    final parts = <String>[];

    if (runDamageBonus != 0) {
      parts.add('Danno run ${runDamageBonus >= 0 ? '+' : ''}$runDamageBonus');
    }
    if (runDefenseBonus != 0) {
      parts.add(
        'Difesa run ${runDefenseBonus >= 0 ? '+' : ''}$runDefenseBonus',
      );
    }
    if (runCritBonus != 0) {
      parts.add('Critico ${runCritBonus >= 0 ? '+' : ''}$runCritBonus');
    }
    if (runLifesteal != 0) parts.add('Furto vita +$runLifesteal');
    if (runHealOnExplore != 0) parts.add('Cura/esplora +$runHealOnExplore');
    if (dodgeCharges > 0) parts.add('Schivate $dodgeCharges');
    if (woundedAllyAssistReady) parts.add('Assist alleato pronto');
    if (criticalShieldActive) parts.add('Scudo Critico attivo');
    if (nextEnemyWeakened) parts.add('Prossimo nemico indebolito');
    if (enemyWeak > 0) parts.add('Debolezza nemica +$enemyWeak');
    if (enemyBurn > 0) parts.add('Bruciatura +$enemyBurn');
    if (enemyBleed > 0) parts.add('Sanguinamento +$enemyBleed');
    if (playerStunTurns > 0) parts.add('Stun giocatore $playerStunTurns');
    if (playerSlowTurns > 0) parts.add('Slow giocatore $playerSlowTurns');
    if (playerBurnTurns > 0) parts.add('Burn giocatore $playerBurnTurns');
    if (playerBleedTurns > 0) parts.add('Bleed giocatore $playerBleedTurns');
    if (playerAttackDebuffTurns > 0) {
      parts.add(
        'Debuff ATK giocatore -$playerAttackDebuffValue (${playerAttackDebuffTurns}t)',
      );
    }
    if (playerDefenseDebuffTurns > 0) {
      parts.add(
        'Debuff DEF giocatore -$playerDefenseDebuffValue (${playerDefenseDebuffTurns}t)',
      );
    }
    if (drownedSummonTurns > 0) parts.add('Affogato $drownedSummonTurns turni');

    final resistances = elementalResist.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${elementName(entry.key)} +${entry.value}')
        .take(4)
        .join(', ');
    if (resistances.isNotEmpty) parts.add('Resistenze: $resistances');

    return parts.isEmpty ? 'nessun buff/debuff speciale' : parts.join(' • ');
  }

  String quickInventorySummary() {
    return 'Vitalium Grezzo $potionMinor • Vitalium Ridefinito $potionMajor • Scudo $potionShield • Ocu $potionOculum • Clean $potionCleanse • Smoke $potionSmoke';
  }

  int potionCount(String type) {
    switch (type) {
      case 'minor':
        return potionMinor;
      case 'major':
        return potionMajor;
      case 'shield':
        return potionShield;
      case 'oculum':
        return potionOculum;
      case 'cleanse':
        return potionCleanse;
      case 'smoke':
        return potionSmoke;
      default:
        return 0;
    }
  }

  void addQuickPotion(String type, {int amount = 1}) {
    switch (type) {
      case 'minor':
        potionMinor += amount;
        break;
      case 'major':
        potionMajor += amount;
        break;
      case 'shield':
        potionShield += amount;
        break;
      case 'oculum':
        potionOculum += amount;
        break;
      case 'cleanse':
        potionCleanse += amount;
        break;
      case 'smoke':
        potionSmoke += amount;
        break;
    }
  }

  bool consumeQuickPotion(String type) {
    if (potionCount(type) <= 0) return false;

    switch (type) {
      case 'minor':
        potionMinor--;
        break;
      case 'major':
        potionMajor--;
        break;
      case 'shield':
        potionShield--;
        break;
      case 'oculum':
        potionOculum--;
        break;
      case 'cleanse':
        potionCleanse--;
        break;
      case 'smoke':
        potionSmoke--;
        break;
      default:
        return false;
    }

    potionsUsed++;
    checkPassiveAchievements();
    return true;
  }

  void showQuickInventory() {
    setState(() {
      clearChoices();

      textIt =
          'Inventario rapido.\n\n'
          'Vitalium, fiale e strumenti veloci della run.\n'
          '${quickInventorySummary()}\n\n'
          'I drop nemici hanno azioni proprie: studia, converti, frantuma o lavora.';
      textEn =
          'Quick inventory.\n\n'
          'Vitalium, vials and quick tools of the run.\n'
          '${quickInventorySummary()}\n\n'
          'Enemy drops have their own actions: study, convert, grind or craft.';

      void addUseChoice({
        required String type,
        required String it,
        required String en,
        required IconData icon,
        required Color color,
      }) {
        if (potionCount(type) <= 0) return;
        eventChoices.add(
          _DungeonChoice(
            labelIt: '$it (${potionCount(type)})',
            labelEn: '$en (${potionCount(type)})',
            icon: icon,
            color: color,
            onPressed: () => useQuickPotion(type),
          ),
        );
      }

      addUseChoice(
        type: 'minor',
        it: 'Vitalium Grezzo',
        en: 'Raw Vitalium',
        icon: Icons.local_hospital,
        color: Colors.greenAccent,
      );
      addUseChoice(
        type: 'major',
        it: 'Vitalium Ridefinito',
        en: 'Redefined Vitalium',
        icon: Icons.local_hospital,
        color: Colors.lightGreenAccent,
      );
      addUseChoice(
        type: 'shield',
        it: 'Fiala Scudo',
        en: 'Shield Vial',
        icon: Icons.shield,
        color: Colors.cyanAccent,
      );
      addUseChoice(
        type: 'oculum',
        it: 'Fiala Oculum',
        en: 'Oculum Vial',
        icon: Icons.visibility,
        color: const Color(0xFF8B5CF6),
      );
      addUseChoice(
        type: 'cleanse',
        it: 'Solvente',
        en: 'Solvent',
        icon: Icons.cleaning_services,
        color: Colors.blueAccent,
      );
      addUseChoice(
        type: 'smoke',
        it: 'Fumo Fuga',
        en: 'Escape Smoke',
        icon: Icons.smoke_free,
        color: Colors.grey,
      );

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Drop nemici',
          labelEn: 'Enemy drops',
          icon: Icons.inventory_2,
          color: widget.tertiaryColor,
          onPressed: showEnemyDropActions,
        ),
      );
    });
  }

  void useQuickPotion(String type) {
    setState(() {
      clearChoices();

      if (!consumeQuickPotion(type)) {
        textIt = 'Non hai questo consumabile.';
        textEn = 'You do not have this consumable.';
        return;
      }

      switch (type) {
        case 'minor':
          final heal = 18 + totalOculum;
          playerHp = min(playerMaxHp, playerHp + heal);
          textIt = 'Vitalium Grezzo.\n+$heal HP.';
          textEn = 'Raw Vitalium.\n+$heal HP.';
          break;

        case 'major':
          final heal = 38 + totalOculum * 2;
          playerHp = min(playerMaxHp, playerHp + heal);
          textIt = 'Vitalium Ridefinito.\n+$heal HP.';
          textEn = 'Redefined Vitalium.\n+$heal HP.';
          break;

        case 'shield':
          final shield = 28 + currentFloor * 3 + totalCm ~/ 2;
          gainPlayerShield(shield);
          textIt = 'Fiala Scudo.\n+$shield Scudo.';
          textEn = 'Shield Vial.\n+$shield Shield.';
          break;

        case 'oculum':
          gainOculumCharges(2);
          dungeonOculum += 1;
          textIt = 'Fiala Oculum.\n+1 Oculum run\n+2 cariche Oculum.';
          textEn = 'Oculum Vial.\n+1 run Oculum\n+2 Oculum charges.';
          break;

        case 'cleanse':
          enemyWeak = 0;
          enemyBleed = 0;
          enemyBurn = 0;
          nextEnemyWeakened = false;
          textIt = 'Solvente usato.\nDebuff ripuliti.';
          textEn = 'Solvent used.\nDebuffs cleaned.';
          break;

        case 'smoke':
          if (!inCombat || enemyIsBoss || enemyIsFetalMan) {
            textIt =
                'Il Fumo non funziona qui. Boss e Uomo Fetale lo ricordano.';
            textEn =
                'The Smoke does not work here. Bosses and the Fetal Man remember it.';
            potionSmoke++;
            potionsUsed = max(0, potionsUsed - 1).toInt();
            return;
          }

          inCombat = false;
          enemyHp = 0;
          enemyParty.clear();
          syncPrimaryEnemyFromParty();
          textIt = 'Fumo Fuga.\nScappi dal fight.';
          textEn = 'Escape Smoke.\nYou flee the fight.';
          break;
      }
    });
  }

  void showEnemyDropActions() {
    setState(() {
      clearChoices();

      textIt =
          'Drop dei nemici.\n\n'
          'Drop nello zaino: ${inventoryDrops.length}\n'
          'Ultimi drop:\n${enemyDropHistoryIt.take(6).join('\n')}\n\n'
          'Azioni: studia, converti, frantuma, incastona o vendi.';
      textEn =
          'Enemy drops.\n\n'
          'Drops in bag: ${inventoryDrops.length}\n'
          'Latest drops:\n${enemyDropHistoryEn.take(6).join('\n')}\n\n'
          'Actions: study, convert, grind, socket or sell.';

      if (inventoryDrops.isEmpty) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Nessun drop',
            labelEn: 'No drops',
            icon: Icons.arrow_back,
            color: Colors.blueGrey,
            onPressed: showQuickInventory,
          ),
        );
        return;
      }

      for (final drop in inventoryDrops.take(5)) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Studia: ${drop.nameIt}',
            labelEn: 'Study: ${drop.nameEn}',
            icon: Icons.menu_book,
            color: elementColor(drop.elementId),
            onPressed: () => studyEnemyDrop(drop),
          ),
        );

        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Converti: ${drop.nameIt}',
            labelEn: 'Convert: ${drop.nameEn}',
            icon: Icons.science,
            color: Colors.greenAccent,
            onPressed: () => convertDropToPotion(drop),
          ),
        );

        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Frantuma in Dust: ${drop.nameIt}',
            labelEn: 'Grind into Dust: ${drop.nameEn}',
            icon: Icons.auto_fix_high,
            color: Colors.amber,
            onPressed: () => grindDropToDust(drop),
          ),
        );
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Fabbro / incastona / vendi',
          labelEn: 'Blacksmith / socket / sell',
          icon: Icons.build,
          color: widget.tertiaryColor,
          onPressed: showDropManagement,
        ),
      );
    });
  }

  void studyEnemyDrop(_UniqueDrop drop) {
    setState(() {
      clearChoices();
      if (!inventoryDrops.contains(drop)) {
        textIt = 'Questo drop non è più disponibile.';
        textEn = 'This drop is no longer available.';
        return;
      }

      inventoryDrops.remove(drop);
      dropsStudied++;
      runCritBonus += 1;
      elementalResist[drop.elementId] =
          (elementalResist[drop.elementId] ?? 0) + 1;

      textIt =
          'Studi il drop e lo consumi:\n${drop.nameIt}\n\n'
          '${drop.descIt}\n\n'
          '+1 critico run\n'
          '+1 resistenza ${elementName(drop.elementId)}.';
      textEn =
          'You study and consume the drop:\n${drop.nameEn}\n\n'
          '${drop.descEn}\n\n'
          '+1 run critical\n'
          '+1 ${elementName(drop.elementId)} resistance.';

      checkPassiveAchievements();
    });
  }

  void convertDropToPotion(_UniqueDrop drop) {
    setState(() {
      if (!inventoryDrops.contains(drop)) {
        textIt = 'Questo drop non è più disponibile.';
        textEn = 'This drop is no longer available.';
        return;
      }

      clearChoices();
      inventoryDrops.remove(drop);
      enemyDropsConverted++;

      switch (drop.elementId) {
        case 'water':
        case 'moon':
        case 'dream':
        case 'flora':
          addQuickPotion('major', amount: 1);
          break;
        case 'earth':
        case 'metal':
        case 'vapium':
        case 'crystal':
        case 'bone':
          addQuickPotion('shield', amount: 1);
          break;
        case 'shadow':
        case 'nullum':
        case 'psyche':
          addQuickPotion('smoke', amount: 1);
          break;
        case 'poison':
        case 'blood':
        case 'ash':
          addQuickPotion('cleanse', amount: 1);
          break;
        default:
          addQuickPotion('oculum', amount: 1);
      }

      textIt =
          'Drop convertito:\n${drop.nameIt}\n\n'
          'Inventario rapido: ${quickInventorySummary()}';
      textEn =
          'Drop converted:\n${drop.nameEn}\n\n'
          'Quick inventory: ${quickInventorySummary()}';

      checkPassiveAchievements();
    });
  }

  void grindDropToDust(_UniqueDrop drop) {
    setState(() {
      if (!inventoryDrops.contains(drop)) {
        textIt = 'Questo drop non è più disponibile.';
        textEn = 'This drop is no longer available.';
        return;
      }

      clearChoices();
      inventoryDrops.remove(drop);

      final dust = 1 + drop.resistBonus ~/ 3;
      ascensionDustInRun += dust;
      blacksmithFavor += 1;

      textIt =
          'Drop frantumato:\n${drop.nameIt}\n\n'
          '+$dust Ascension Dust\n'
          '+1 favore del fabbro.';
      textEn =
          'Drop ground:\n${drop.nameEn}\n\n'
          '+$dust Ascension Dust\n'
          '+1 blacksmith favor.';
    });
  }

  void unlockRandomGoodNpc() {
    final locked = _goodNpcs
        .where((npc) => !unlockedNpcIds.contains(npc.id))
        .toList();

    if (locked.isEmpty) return;

    final npc = locked[_random.nextInt(locked.length)];
    unlockedNpcIds.add(npc.id);
    _savePermanentProgress();

    addLog(
      t(
        'NPC buono sbloccato: ${npc.nameIt}.',
        'Good NPC unlocked: ${npc.nameEn}.',
      ),
    );
  }

  bool canUseArtTechnique() {
    if (!runActive ||
        gameOver ||
        enemyTurnPending ||
        activeArt == null ||
        artTechniqueCooldown > 0) {
      return false;
    }

    if (activeArt?.effectId == 'thousand_fires_emblem_art') {
      return isInLastSixteenRooms;
    }

    if (activeArt?.effectId == 'water_necromancy_art') {
      return oculumCharges >= 3;
    }

    return oculumCharges >= 2;
  }

  bool canUseRelicSkill() {
    if (!runActive || gameOver || enemyTurnPending || activeRelic == null) {
      return false;
    }
    if (relicSkillUsesThisRoom > 0) return false;
    return true;
  }

  void useRelicSkill() {
    if (!canUseRelicSkill()) {
      setState(() {
        textIt =
            'Skill Reliquia non disponibile.\n\n'
            'Regola: una Skill Reliquia per stanza.\n'
            'L’Open può potenziarla fino a fine piano, ma non renderla infinita.';
        textEn =
            'Relic Skill unavailable.\n\n'
            'Rule: one Relic Skill per room.\n'
            'The Open can empower it until floor end, but cannot make it infinite.';
      });
      return;
    }

    setState(() {
      final effect = activeRelic!.effectId;
      relicSkillUsesThisRoom++;
      final empowered = relicOpenLastFloor[effect] == currentFloor;
      final power = empowered ? 2 : 1;
      relicSkillUsesThisFloor++;

      clearChoices();

      if (effect == 'open_cipo_serpent') {
        final damage = 5 + totalDamage ~/ 2 + totalOculum + currentFloor;
        enemyWeak += 1 + power;
        if (inCombat && enemyParty.isNotEmpty) {
          final target = firstAliveEnemy();
          if (target != null) {
            target.hp = max(0, target.hp - damage).toInt();
            target.defense = max(0, target.defense - (1 + power)).toInt();
          }
          defeatDeadEnemiesFromParty();
          syncPrimaryEnemyFromParty();
        }
        textIt =
            'Skill Reliquia — Cipo non è solo.\n\n'
            'La bocca del serpente morde: $damage danni, fragilità +${1 + power} e +5 danni passivi finché il serpente vive.';
        textEn =
            'Relic Skill — Cipo Is Not Alone.\n\n'
            'The serpent mouth bites: $damage damage, fragility +${1 + power} and +5 passive damage while the serpent lives.';
        if (enemyParty.isEmpty && inCombat) completeCombatVictory();
        return;
      }

      if (effect == 'open_soldier_prayer') {
        final bonus = 1 + _random.nextInt(6);
        relicNextRollBonus += bonus;
        gainPlayerShield(6 * power);
        textIt =
            'Skill Reliquia — Preghiera del Soldato.\n\n'
            '+$bonus al prossimo tiro.\n+${6 * power} Scudo.';
        textEn =
            'Relic Skill — Soldier Prayer.\n\n'
            '+$bonus on the next roll.\n+${6 * power} Shield.';
        return;
      }

      if (effect == 'open_floral_focus') {
        floralGuardCharges += power;
        gainPlayerShield(8 * power);
        textIt =
            'Skill Reliquia — Concentrazione Floreale.\n\n'
            '+$power umano floreale di guardia.\n+${8 * power} Scudo.';
        textEn =
            'Relic Skill — Floral Focus.\n\n'
            '+$power floral human guard.\n+${8 * power} Shield.';
        return;
      }

      if (effect == 'open_tribal_dance') {
        final extraHits = tribalDanceBuffFloor == currentFloor ? 2 : 0;
        final hits = 1 + _random.nextInt(4) + extraHits;
        final firstHit = max(1, totalDamage + currentFloor);
        final followHit = max(1, firstHit ~/ 2);
        final damage = firstHit + max(0, hits - 1) * followHit;
        if (tribalDanceBuffFloor == currentFloor) gainPlayerShield(50);
        if (inCombat && enemyParty.isNotEmpty) {
          final target = firstAliveEnemy();
          if (target != null) target.hp = max(0, target.hp - damage).toInt();
          defeatDeadEnemiesFromParty();
          syncPrimaryEnemyFromParty();
        }
        textIt =
            'Skill Reliquia — Danza Tribale.\n\n'
            '$hits colpi: $damage danni totali.${tribalDanceBuffFloor == currentFloor ? '\nBuff Open: +2 colpi e +50 HP temporanei/Scudo.' : ''}';
        textEn =
            'Relic Skill — Tribal Dance.\n\n'
            '$hits hits: $damage total damage.${tribalDanceBuffFloor == currentFloor ? '\nOpen buff: +2 hits and +50 temporary HP/Shield.' : ''}';
        if (enemyParty.isEmpty && inCombat) completeCombatVictory();
        return;
      }

      if (effect == 'open_ego_shield') {
        if (egoWeaponStacks < 5) egoWeaponStacks++;
        if (egoShieldBuffFloor == currentFloor) egoDefenseStacks++;
        textIt =
            "Skill Reliquia — Scudo dell'Io.\n\n"
            '+5 danni per questo fight. Stack: $egoWeaponStacks/5.'
            '${egoShieldBuffFloor == currentFloor ? '\nBuff Open: +2 difesa.' : ''}';
        textEn =
            'Relic Skill — Shield of the Self.\n\n'
            '+5 damage for this fight. Stacks: $egoWeaponStacks/5.'
            '${egoShieldBuffFloor == currentFloor ? '\nOpen buff: +2 defense.' : ''}';
        return;
      }

      final damage = 5 * power + totalOculum + currentFloor;
      final shield = 6 * power;

      if (effect.contains('nature') || effect.contains('root')) {
        playerHp = min(playerMaxHp, playerHp + 4 * power + titleResBonus);
        enemyWeak += power;
      } else if (effect.contains('moon')) {
        gainPlayerShield(shield + 8);
        nextEnemyWeakened = true;
      } else if (effect.contains('star')) {
        runCritBonus += 2 * power;
        enemyWeak += power;
      } else if (effect.contains('fire')) {
        enemyBurn += 3 * power;
      } else if (effect.contains('summon')) {
        skellyGuardCharges += power;
      } else if (effect.contains('water')) {
        enemyWeak += 2 * power;
        playerHp = min(playerMaxHp, playerHp + 3 * power);
      } else if (effect.contains('wind')) {
        dodgeCharges += power;
      } else if (effect.contains('bone')) {
        gainPlayerShield(10 * power);
      } else if (effect == 'fifi_sleep') {
        fifiSleepActions = max(fifiSleepActions, power);
      } else if (effect == 'hoshy_open') {
        runCritBonus += 3 * power;
      } else if (effect == 'vervain_open') {
        enemyWeak += 2 * power;
      }
      gainPlayerShield(shield);

      if (inCombat && enemyParty.isNotEmpty) {
        final target = enemyParty.firstWhere(
          (e) => e.hp > 0,
          orElse: () => enemyParty.first,
        );
        target.hp = max(0, target.hp - damage).toInt();
        defeatDeadEnemiesFromParty();
        syncPrimaryEnemyFromParty();
      }

      textIt =
          'Skill reliquia ${empowered ? 'potenziata' : 'depotenziata'}.\n'
          '$damage danni se in fight.\n'
          '+$shield Scudo.\n'
          'Effetto: ${activeRelic!.nameIt}.';
      textEn =
          'Relic skill ${empowered ? 'empowered' : 'weakened'}.\n'
          '$damage damage if in fight.\n'
          '+$shield Shield.\n'
          'Effect: ${activeRelic!.nameEn}.';

      if (enemyParty.isEmpty && inCombat) completeCombatVictory();
    });
  }

  bool canUseRelicOpen() {
    if (!runActive || gameOver || enemyTurnPending || activeRelic == null) {
      return false;
    }
    final effect = activeRelic!.effectId;
    return relicOpenLastFloor[effect] != currentFloor;
  }

  void useRelicOpen() {
    if (!canUseRelicOpen()) {
      setState(() {
        final relicName = activeRelic == null
            ? t('nessuna reliquia', 'no relic')
            : widget.linguaInglese
            ? activeRelic!.nameEn
            : activeRelic!.nameIt;
        textIt =
            'Open Reliquia non disponibile.\n\n'
            'Reliquia: $relicName\n'
            'Regola: una Open per piano.';
        textEn =
            'Relic Open unavailable.\n\n'
            'Relic: $relicName\n'
            'Rule: one Open per floor.';
      });
      return;
    }

    setState(() {
      final relic = activeRelic!;
      final effect = relic.effectId;
      relicOpenLastFloor[effect] = currentFloor;
      clearChoices();

      if (effect == 'open_cipo_serpent') {
        cipoSerpentMaxHp = max(1, playerMaxHp * 2).toInt();
        cipoSerpentHp = cipoSerpentMaxHp;
        textIt =
            'Open — Cipo non è solo.\n\n'
            'Un enorme serpente di legno nasce con una luce verde dentro.\n'
            'HP serpente: $cipoSerpentHp/$cipoSerpentMaxHp.\n'
            '+5 ai tiri, +5 danni, e il serpente attira i colpi nemici.';
        textEn =
            'Open — Cipo Is Not Alone.\n\n'
            'A huge wooden serpent rises with green light inside.\n'
            'Serpent HP: $cipoSerpentHp/$cipoSerpentMaxHp.\n'
            '+5 rolls, +5 damage, and the serpent draws enemy hits.';
        return;
      }

      if (effect == 'open_soldier_prayer') {
        final bonus = 1 + _random.nextInt(20);
        relicNextRollBonus += bonus;
        dungeonResilienza += 6;
        dungeonVolonta += 6;
        dungeonMateria += 6;
        dungeonOculum += 6;
        textIt =
            'Open — Preghiera del Soldato.\n\n'
            'Mani giganti di energia gialla compaiono dietro di te.\n'
            '+$bonus al prossimo tiro.\n'
            '+6 a tutte le stats.';
        textEn =
            'Open — Soldier Prayer.\n\n'
            'Giant yellow energy hands appear behind you.\n'
            '+$bonus on the next roll.\n'
            '+6 to all stats.';
        return;
      }

      if (effect == 'open_floral_focus') {
        final guards = 1 + _random.nextInt(6);
        floralGuardCharges += guards;
        gainPlayerShield(guards * 10);
        textIt =
            'Open — Concentrazione Floreale.\n\n'
            'La terra fiorisce in rosa e rialza $guards umani.\n'
            'Si pietrificheranno per salvarti.\n'
            '+${guards * 10} Scudo.';
        textEn =
            'Open — Floral Focus.\n\n'
            'The earth blooms pink and raises $guards humans.\n'
            'They will petrify to save you.\n'
            '+${guards * 10} Shield.';
        return;
      }

      if (effect == 'open_tribal_dance') {
        final hits = 3 + _random.nextInt(6);
        final firstHit = max(1, totalDamage + totalVc ~/ 2 + currentFloor);
        final followHit = max(1, firstHit ~/ 2);
        final damage = firstHit + (hits - 1) * followHit;
        tribalDanceBuffFloor = currentFloor;
        gainPlayerShield(50);
        if (inCombat && enemyParty.isNotEmpty) {
          for (final enemy in enemyParty.where((e) => e.hp > 0)) {
            enemy.hp = max(0, enemy.hp - damage).toInt();
          }
          defeatDeadEnemiesFromParty();
          syncPrimaryEnemyFromParty();
        }
        textIt =
            'Open — Danza Tribale.\n\n'
            '$hits colpi danzati: $damage danni totali.\n'
            'La Skill Reliquia ottiene +2 colpi fino a fine piano.\n'
            '+50 HP temporanei/Scudo.';
        textEn =
            'Open — Tribal Dance.\n\n'
            '$hits danced hits: $damage total damage.\n'
            'Relic Skill gets +2 hits until floor end.\n'
            '+50 temporary HP/Shield.';
        if (enemyParty.isEmpty && inCombat) completeCombatVictory();
        return;
      }

      if (effect == 'open_ego_shield') {
        egoShieldHp = max(1, totalCm + 10).toInt();
        egoShieldBuffFloor = currentFloor;
        textIt =
            "Open — Scudo dell'Io.\n\n"
            "Uno scudo gigantesco di volontà d'oro appare davanti a te.\n"
            'HP Scudo: $egoShieldHp.\n'
            'La Skill Reliquia ora dà anche +2 difesa.';
        textEn =
            'Open — Shield of the Self.\n\n'
            'A giant shield of golden will appears before you.\n'
            'Shield HP: $egoShieldHp.\n'
            'Relic Skill now also grants +2 defense.';
        return;
      }

      if (effect.startsWith('open_')) {
        final damage = 18 + totalOculum * 2 + currentFloor * 5;
        final shield = eventShieldGain(14 + currentFloor * 3);
        gainPlayerShield(shield);
        enemyWeak += 3;
        if (effect.contains('nature')) {
          playerHp = min(playerMaxHp, playerHp + 18 + titleResBonus);
        } else if (effect.contains('moon')) {
          criticalShieldActive = true;
        } else if (effect.contains('star')) {
          runCritBonus += 12;
        } else if (effect.contains('fire')) {
          enemyBurn += 10;
        } else if (effect.contains('summon')) {
          skellyGuardCharges += 3;
        } else if (effect.contains('water')) {
          fifiSleepActions = max(fifiSleepActions, 2);
        } else if (effect.contains('wind')) {
          dodgeCharges += 3;
        } else if (effect.contains('bone')) {
          runDefenseBonus += 3;
        }

        if (inCombat && enemyParty.isNotEmpty) {
          for (final enemy in enemyParty.where((e) => e.hp > 0)) {
            enemy.hp = max(0, enemy.hp - damage).toInt();
          }
          defeatDeadEnemiesFromParty();
          syncPrimaryEnemyFromParty();
        }

        textIt =
            'Open — ${relic.nameIt}.\n\n'
            'Versione macabra della reliquia: $damage danni, +$shield Scudo, debuff nemici.\n'
            'La skill minore di questa reliquia è potenziata fino alla fine del piano.';
        textEn =
            'Open — ${relic.nameEn}.\n\n'
            'Macabre relic version: $damage damage, +$shield Shield, enemy debuff.\n'
            'This relic lesser skill is empowered until the end of the floor.';

        if (enemyParty.isEmpty && inCombat) completeCombatVictory();
        return;
      }

      if (effect == 'fifi_sleep') {
        final sleep = 1 + _random.nextInt(6);
        fifiSleepActions = max(fifiSleepActions, sleep);
        enemyWeak += 2;
        textIt =
            'Open — Carillon di Fifi.\n\nGli avversari si addormentano per $sleep azioni.';
        textEn =
            'Open — Fifi Music Box.\n\nEnemies fall asleep for $sleep actions.';
        return;
      }

      if (effect == 'hoshy_open') {
        final roll = 1 + _random.nextInt(100);
        final damage = roll * 2 + totalDamage;
        final partySize =
            1 +
            activeAllies.length +
            (pawnHp > 0 ? 1 : 0) +
            (skeletonHandsHp > 0 ? 1 : 0);
        final shield = 20 * partySize;

        if (inCombat && enemyParty.isNotEmpty) {
          for (final enemy in enemyParty.where((e) => e.hp > 0)) {
            enemy.hp = max(0, enemy.hp - damage).toInt();
          }
          defeatDeadEnemiesFromParty();
          syncPrimaryEnemyFromParty();
        }

        gainPlayerShield(shield);
        textIt =
            'Open — Graffi Sonici di Hoshy.\n\n'
            'Roll: $roll\n'
            '$damage danni a tutti i nemici.\n'
            '+$shield Scudo al party.';
        textEn =
            'Open — Hoshy Sonic Scratches.\n\n'
            'Roll: $roll\n'
            '$damage damage to all enemies.\n'
            '+$shield party Shield.';

        if (enemyParty.isEmpty && inCombat) completeCombatVictory();
        return;
      }

      if (effect == 'vervain_open') {
        final damage = 20 + totalOculum * 2 + currentFloor * 4;
        if (vervainBuffFloor != currentFloor) {
          vervainBuffFloor = currentFloor;
          dungeonResilienza += 5;
          dungeonVolonta += 5;
          dungeonMateria += 5;
          dungeonOculum += 5;
          addMaxHp(50);
        }

        fifiSleepActions = max(fifiSleepActions, 2);
        enemyWeak += 5;

        if (inCombat && enemyParty.isNotEmpty) {
          for (final enemy in enemyParty.where((e) => e.hp > 0)) {
            enemy.hp = max(0, enemy.hp - damage).toInt();
            enemy.attack = max(1, enemy.attack - 4).toInt();
          }
          defeatDeadEnemiesFromParty();
          syncPrimaryEnemyFromParty();
        }

        textIt =
            'Open — Vermi Decadenti di Vervain.\n\n'
            'Fibre floreali divorano e immobilizzano.\n'
            '+5 a tutte le stats fino a fine piano.\n'
            '$damage danni e nemici immobilizzati.';
        textEn =
            'Open — Vervain Decaying Worms.\n\n'
            'Floral fibers devour and immobilize.\n'
            '+5 to all stats until floor end.\n'
            '$damage damage and enemies immobilized.';

        if (enemyParty.isEmpty && inCombat) completeCombatVictory();
        return;
      }

      final damage = 14 + totalOculum * 2 + totalDamage ~/ 2 + currentFloor * 3;
      final shield = eventShieldGain(12 + totalDefense ~/ 2 + currentFloor * 2);
      gainPlayerShield(shield);
      enemyWeak += 2;

      if (effect.contains('leaf') || effect.contains('root')) {
        playerHp = min(playerMaxHp, playerHp + 12 + titleResBonus);
      } else if (effect.contains('gear') || effect.contains('kooba')) {
        sparklingGears += 1;
        runCritBonus += 3;
      } else if (effect.contains('vitalium') || effect.contains('rebirth')) {
        addMaxHp(12);
      } else if (effect.contains('pawn')) {
        pawnHp = max(pawnHp, pawnMaxHp);
        pawnShield += 20;
      } else if (effect.contains('baghest') || effect.contains('oculian')) {
        nextEnemyWeakened = true;
        dodgeCharges += 2;
      } else if (effect.contains('feather') || effect.contains('wind')) {
        dodgeCharges += 3;
      } else if (effect.contains('obser')) {
        obserInRun += 8;
      } else if (effect.contains('bone') || effect.contains('skeleton')) {
        skellyGuardCharges += 2;
      }

      if (inCombat && enemyParty.isNotEmpty) {
        for (final enemy in enemyParty.where((enemy) => enemy.hp > 0)) {
          enemy.hp = max(0, enemy.hp - damage).toInt();
          enemy.attack = max(1, enemy.attack - 1).toInt();
        }
        defeatDeadEnemiesFromParty();
        syncPrimaryEnemyFromParty();
      }

      textIt =
          'Open — ${relic.nameIt}.\n\n'
          'La reliquia scarica la sua forma attiva.\n'
          '$damage danni ad area se in fight, +$shield Scudo, nemici indeboliti.\n'
          'La Skill Reliquia resta potenziata fino alla fine del piano.';
      textEn =
          'Open — ${relic.nameEn}.\n\n'
          'The relic releases its active form.\n'
          '$damage area damage if in fight, +$shield Shield, enemies weakened.\n'
          'The Relic Skill stays empowered until the end of the floor.';

      if (enemyParty.isEmpty && inCombat) completeCombatVictory();
    });
  }

  void useArtTechnique() {
    if (!canUseArtTechnique()) {
      setState(() {
        final artId = activeArt?.effectId ?? '';
        final specialNeed = artId == 'thousand_fires_emblem_art'
            ? 'Mille Fuochi funziona solo nelle ultime 16 stanze e con cooldown a 0.'
            : artId == 'water_necromancy_art'
            ? 'Necromanzia Acquatica richiede 3 Oculum totali e cooldown a 0.'
            : 'Serve una Art attiva, 2 cariche Oculum e cooldown a 0.';
        textIt =
            'Tecnica Art non disponibile.\n\n'
            '$specialNeed\n'
            'Cooldown attuale: $artTechniqueCooldown.';
        textEn =
            'Art Technique unavailable.\n\n'
            '${artId == 'thousand_fires_emblem_art'
                ? 'Thousand Fires works only in the last 16 rooms and with cooldown at 0.'
                : artId == 'water_necromancy_art'
                ? 'Aquatic Necromancy requires 3 total Oculum and cooldown at 0.'
                : 'You need an active Art, 2 Oculum charges and cooldown at 0.'}\n'
            'Current cooldown: $artTechniqueCooldown.';
      });
      return;
    }

    setState(() {
      clearChoices();

      final element = activeElementId;
      final elementIt = elementName(element);
      final artId = activeArt?.effectId ?? '';

      if (artId == 'thousand_fires_emblem_art') {
        completeAchievement('mille_fuochi_used');
        artTechniqueCooldown = 2;
        artTechniqueUses++;
        checkPassiveAchievements();

        final finalPressure = max(1, 17 - roomsRemainingInRun);
        final flames = 12 + currentFloor * 2 + dungeonLevel * 3 + finalPressure;
        final bonusBurn = 8 + oculumArtPower + finalPressure;
        final shieldGain = 20 + flames;
        final critGain = 6 + finalPressure ~/ 2;

        gainPlayerShield(shieldGain);
        runCritBonus += critGain;
        enemyBurn += bonusBurn;

        if (inCombat && enemyParty.isNotEmpty) {
          for (final enemy in enemyParty) {
            final executeBonus = enemy.boss ? flames * 2 : flames;
            final damage =
                flames +
                totalDamage +
                oculumArtPower +
                runDamageBonus +
                executeBonus;
            enemy.hp = max(0, enemy.hp - damage).toInt();
            enemy.attack = max(1, enemy.attack - 2).toInt();
            enemy.defense = max(0, enemy.defense - 1).toInt();
          }

          defeatDeadEnemiesFromParty();
          if (enemyParty.isEmpty) {
            completeCombatVictory();
            return;
          }

          syncPrimaryEnemyFromParty();
          textIt =
              'Emblem Art dei Mille Fuochi.\n\n'
              'Costo: 0 Oculum. Cooldown: 2 azioni.\n'
              'Le fiamme finali devastano il gruppo nemico.\n'
              '+$shieldGain Scudo, +$critGain critico, Bruciatura +$bonusBurn.';
          textEn =
              'Thousand Fires Emblem Art.\n\n'
              'Cost: 0 Oculum. Cooldown: 2 actions.\n'
              'Final flames devastate the enemy group.\n'
              '+$shieldGain Shield, +$critGain critical, Burn +$bonusBurn.';
          enemyTurn();
          return;
        }

        runDamageBonus += flames ~/ 2;
        textIt =
            'Emblem Art dei Mille Fuochi.\n\n'
            'Costo: 0 Oculum. Cooldown: 2 azioni.\n'
            '+${flames ~/ 2} danni run, +$shieldGain Scudo, +$critGain critico.';
        textEn =
            'Thousand Fires Emblem Art.\n\n'
            'Cost: 0 Oculum. Cooldown: 2 actions.\n'
            '+${flames ~/ 2} run damage, +$shieldGain Shield, +$critGain critical.';
        return;
      }

      oculumCharges -= 2;
      artTechniqueCooldown = 3;
      artTechniqueUses++;
      checkPassiveAchievements();

      final usesDrownedTechnique =
          artId == 'water_necromancy_art' ||
          (activeArt?.elementId == 'water' && hasUnlockedDrownedChainSkill());

      if (usesDrownedTechnique) {
        final isFullNecromancy = artId == 'water_necromancy_art';

        if (isFullNecromancy && oculumCharges < 1) {
          textIt =
              'Necromanzia Acquatica richiede 3 Oculum totali.\n\n'
              'La Tecnica Art ha già preso 2 cariche, ma manca la terza.';
          textEn =
              'Aquatic Necromancy requires 3 total Oculum.\n\n'
              'The Art Technique already took 2 charges, but the third is missing.';
          gainOculumCharges(2);
          artTechniqueCooldown = 0;
          return;
        }

        if (isFullNecromancy) {
          oculumCharges -=
              1; // costo totale 3: 2 già spesi dalla tecnica, 1 extra qui.
        }

        final power = isFullNecromancy ? 3 : 2;
        armDrownedArtNecromancy(power: power);
        drownedSummonTurns = max(drownedSummonTurns, 3).toInt();
        completeAchievement('drowned_magic');

        final limitLineIt = maxTemporaryDrowned == 4
            ? 'Il Romanzo tiene aperto il quarto Affogato.'
            : 'Senza Romanzo il limite resta 3 Affogati.';
        final limitLineEn = maxTemporaryDrowned == 4
            ? 'The Novel keeps the fourth Drowned open.'
            : 'Without the Novel the limit remains 3 Drowned.';

        if (inCombat && enemyParty.any((enemy) => enemy.hp > 0)) {
          final damage =
              (isFullNecromancy ? 10 : 6) +
              oculumArtPower +
              currentFloor +
              dungeonLevel;
          for (final enemy in enemyParty.where((enemy) => enemy.hp > 0)) {
            enemy.hp = max(0, enemy.hp - damage).toInt();
            enemy.attack = max(1, enemy.attack - 1).toInt();
          }

          enemyWeak += isFullNecromancy ? 3 : 2;

          textIt =
              '${isFullNecromancy ? 'Tecnica Art: Necromanzia Acquatica' : 'Tecnica Art: Catena d’Annegamento'}\n\n'
              'Costo: ${isFullNecromancy ? '3' : '2'} Oculum.\n'
              'L’acqua morta entra nel fight: $damage danni a ogni nemico e Debolezza aumentata.\n'
              'Se i nemici cadono, resteranno come Affogati temporanei per 3 azioni.\n'
              '$limitLineIt\n'
              'Affogati attivi ora: $activeTemporaryDrownedCount/$maxTemporaryDrowned.';
          textEn =
              '${isFullNecromancy ? 'Art Technique: Aquatic Necromancy' : 'Art Technique: Drowning Chain'}\n\n'
              'Cost: ${isFullNecromancy ? '3' : '2'} Oculum.\n'
              'Dead water enters the fight: $damage damage to every enemy and increased Weakness.\n'
              'If enemies fall, they will remain as Temporary Drowned for 3 actions.\n'
              '$limitLineEn\n'
              'Drowned active now: $activeTemporaryDrownedCount/$maxTemporaryDrowned.';

          defeatDeadEnemiesFromParty();
          if (enemyParty.isEmpty) {
            completeCombatVictory();
            return;
          }

          syncPrimaryEnemyFromParty();
          enemyTurn();
        } else {
          gainPlayerShield(isFullNecromancy ? 12 : 6);
          textIt =
              '${isFullNecromancy ? 'Tecnica Art: Necromanzia Acquatica' : 'Tecnica Art: Catena d’Annegamento'}\n\n'
              'Prepari l’acqua morta: il prossimo fight potrà lasciare caduti come Affogati temporanei.\n'
              '$limitLineIt\n'
              '+${isFullNecromancy ? 12 : 6} Scudo.';
          textEn =
              '${isFullNecromancy ? 'Art Technique: Aquatic Necromancy' : 'Art Technique: Drowning Chain'}\n\n'
              'You prepare dead water: the next fight may leave fallen enemies as Temporary Drowned.\n'
              '$limitLineEn\n'
              '+${isFullNecromancy ? 12 : 6} Shield.';
        }

        saveRunCheckpoint(
          reasonIt: 'Tecnica Art degli Affogati registrata.',
          reasonEn: 'Drowned Art Technique recorded.',
        );
        return;
      }

      if (artId == 'asher_fire_art') {
        runDamageBonus += max(3, (dungeonLevel + 1) * 3);
        enemyBurn += 4 + oculumArtPower;
        textIt =
            'Fuoco di Asher.\n'
            '+${max(3, (dungeonLevel + 1) * 3)} danni run e forte Bruciatura.';
        textEn =
            'Asher Fire.\n'
            '+${max(3, (dungeonLevel + 1) * 3)} run damage and strong Burn.';
        return;
      }

      switch (element) {
        case 'fire':
        case 'lava':
          if (inCombat && enemyParty.isNotEmpty) {
            for (final enemy in enemyParty) {
              enemy.hp = max(
                0,
                enemy.hp - (8 + oculumArtPower + currentFloor),
              ).toInt();
            }
            enemyBurn += 3 + oculumArtPower ~/ 2;
            textIt =
                'Tecnica Art: $elementIt.\nColpisce tutti e aumenta Bruciatura.';
            textEn = 'Art Technique: $elementIt.\nHits all and increases Burn.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            runDamageBonus += 3;
            textIt = 'Tecnica Art: $elementIt.\n+3 danni run.';
            textEn = 'Art Technique: $elementIt.\n+3 run damage.';
          }
          break;

        case 'water':
        case 'moon':
          final heal = 28 + oculumArtPower;
          playerHp = min(playerMaxHp, playerHp + heal);
          gainOculumCharges(1);
          final lockedDrownedHintIt =
              element == 'water' && !hasUnlockedDrownedChainSkill()
              ? '\nCatena d’Annegamento non è ancora sbloccata: per ora la Tecnica Art cura soltanto.'
              : '';
          final lockedDrownedHintEn =
              element == 'water' && !hasUnlockedDrownedChainSkill()
              ? '\nDrowning Chain is not unlocked yet: for now the Art Technique only heals.'
              : '';
          textIt =
              'Tecnica Art: $elementIt.\n+$heal HP e +1 carica Oculum.$lockedDrownedHintIt';
          textEn =
              'Art Technique: $elementIt.\n+$heal HP and +1 Oculum charge.$lockedDrownedHintEn';
          break;

        case 'wind':
        case 'lightning':
          dodgeCharges += 2;
          runCritBonus += 4;
          if (inCombat && enemyParty.isNotEmpty) {
            final target = enemyParty[_random.nextInt(enemyParty.length)];
            final damage = 18 + oculumArtPower + combo;
            target.hp = max(0, target.hp - damage).toInt();
            textIt =
                'Tecnica Art: $elementIt.\n+$damage danni rapidi, +2 schivate.';
            textEn =
                'Art Technique: $elementIt.\n+$damage fast damage, +2 dodges.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
          } else {
            textIt = 'Tecnica Art: $elementIt.\n+2 schivate, +4 critico.';
            textEn = 'Art Technique: $elementIt.\n+2 dodges, +4 critical.';
          }
          break;

        case 'earth':
        case 'bone':
        case 'metal':
        case 'vapium':
          final shield = 35 + totalCm + currentFloor * 3;
          gainPlayerShield(shield);
          runDefenseBonus += 2;
          textIt = 'Tecnica Art: $elementIt.\n+$shield Scudo e +2 difesa run.';
          textEn =
              'Art Technique: $elementIt.\n+$shield Shield and +2 run defense.';
          break;

        case 'ice':
        case 'sound':
        case 'psyche':
        case 'dream':
          enemyWeak += 3;
          nextEnemyWeakened = true;
          if (inCombat) {
            for (final enemy in enemyParty) {
              enemy.attack = max(1, enemy.attack - 2).toInt();
            }
          }
          textIt =
              'Tecnica Art: $elementIt.\nNemici indeboliti, prossimo nemico indebolito.';
          textEn =
              'Art Technique: $elementIt.\nEnemies weakened, next enemy weakened.';
          break;

        case 'poison':
        case 'blood':
        case 'ash':
        case 'shadow':
        case 'nullum':
          if (inCombat && enemyParty.isNotEmpty) {
            final target = enemyParty.first;
            final damage = 20 + oculumArtPower + runLifesteal * 4;
            target.hp = max(0, target.hp - damage).toInt();
            playerHp = min(playerMaxHp, playerHp + max(6, damage ~/ 3));
            enemyBleed += 3;
            textIt =
                'Tecnica Art: $elementIt.\nDanno singolo forte, furto vita e Sanguinamento.';
            textEn =
                'Art Technique: $elementIt.\nStrong single damage, lifesteal and Bleed.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
            enemyTurn();
          } else {
            runLifesteal += 1;
            textIt = 'Tecnica Art: $elementIt.\n+1 furto vita run.';
            textEn = 'Art Technique: $elementIt.\n+1 run lifesteal.';
          }
          break;

        case 'crystal':
        case 'sun':
        case 'gravity':
          runCritBonus += 8;
          if (inCombat && enemyParty.isNotEmpty) {
            final damage = 16 + totalDamage ~/ 2 + oculumArtPower;
            final target = firstAliveEnemy() ?? enemyParty.first;
            target.hp = max(0, target.hp - damage).toInt();
            textIt =
                'Tecnica Art: $elementIt.\nColpo preciso: $damage danni e +8 critico run.';
            textEn =
                'Art Technique: $elementIt.\nPrecise hit: $damage damage and +8 run critical.';
            defeatDeadEnemiesFromParty();
            if (enemyParty.isEmpty) {
              completeCombatVictory();
              return;
            }
            syncPrimaryEnemyFromParty();
          } else {
            textIt = 'Tecnica Art: $elementIt.\n+8 critico run.';
            textEn = 'Art Technique: $elementIt.\n+8 run critical.';
          }
          break;

        default:
          dungeonOculum += 1;
          gainPlayerShield(20);
          textIt = 'Tecnica Art: $elementIt.\n+1 Oculum run e +20 Scudo.';
          textEn = 'Art Technique: $elementIt.\n+1 run Oculum and +20 Shield.';
      }
    });
  }

  void showDropManagement() {
    setState(() {
      clearChoices();
      textIt =
          'Drop unici nello zaino.\n\n'
          'Puoi incastonarli nell’arma o venderli al fabbro per Obser, Dust e favore.';
      textEn =
          'Unique drops in your bag.\n\n'
          'You can socket them into the weapon or sell them to the blacksmith for Obser, Dust and favor.';

      for (final drop in inventoryDrops.take(8)) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Incastona: ${drop.nameIt}',
            labelEn: 'Socket: ${drop.nameEn}',
            icon: Icons.radio_button_checked,
            color: elementColor(drop.elementId),
            onPressed: () => attachDrop(drop),
          ),
        );
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Vendi: ${drop.nameIt}',
            labelEn: 'Sell: ${drop.nameEn}',
            icon: Icons.sell,
            color: Colors.amber,
            onPressed: () => sellDrop(drop),
          ),
        );
      }
    });
  }

  void attachDrop(_UniqueDrop drop) {
    setState(() {
      if (!inventoryDrops.contains(drop)) {
        textIt = 'Questo drop non è più disponibile.';
        textEn = 'This drop is no longer available.';
        return;
      }

      if (blacksmithActionUsedThisRoom || dropActionUsedThisRoom) {
        textIt = 'Puoi lavorare un solo drop per visita.';
        textEn = 'You can work only one drop per visit.';
        return;
      }
      blacksmithActionUsedThisRoom = true;
      dropActionUsedThisRoom = true;
      clearChoices();
      inventoryDrops.remove(drop);
      attachedDrops.add(
        _AttachedDrop(
          dropId: drop.id,
          nameIt: drop.nameIt,
          nameEn: drop.nameEn,
          elementId: drop.elementId,
          damageBonus: drop.damageBonus,
          defenseBonus: drop.defenseBonus,
          resistBonus: drop.resistBonus,
        ),
      );
      elementalResist[drop.elementId] =
          (elementalResist[drop.elementId] ?? 0) + drop.resistBonus;
      completeAchievement('drop_socketed');

      textIt =
          'Drop incastonato nell’arma:\n${drop.nameIt}\n\n'
          '+${drop.damageBonus} danni\n'
          '+${drop.defenseBonus} difesa\n'
          '+${drop.resistBonus} resistenza ${elementName(drop.elementId)}';
      textEn =
          'Drop socketed into weapon:\n${drop.nameEn}\n\n'
          '+${drop.damageBonus} damage\n'
          '+${drop.defenseBonus} defense\n'
          '+${drop.resistBonus} ${elementName(drop.elementId)} resistance';
    });
  }

  void sellDrop(_UniqueDrop drop) {
    setState(() {
      if (!inventoryDrops.contains(drop)) {
        textIt = 'Questo drop non è più disponibile.';
        textEn = 'This drop is no longer available.';
        return;
      }

      if (blacksmithActionUsedThisRoom || dropActionUsedThisRoom) {
        textIt = 'Puoi lavorare un solo drop per visita.';
        textEn = 'You can work only one drop per visit.';
        return;
      }
      blacksmithActionUsedThisRoom = true;
      dropActionUsedThisRoom = true;
      clearChoices();
      inventoryDrops.remove(drop);
      obserInRun += drop.sellObser;
      ascensionDustInRun += drop.sellDust;
      blacksmithFavor += 1;

      textIt =
          'Drop venduto al fabbro:\n${drop.nameIt}\n\n'
          '+${drop.sellObser} Obser\n'
          '+${drop.sellDust} Dust\n'
          '+1 favore del fabbro.';
      textEn =
          'Drop sold to the blacksmith:\n${drop.nameEn}\n\n'
          '+${drop.sellObser} Obser\n'
          '+${drop.sellDust} Dust\n'
          '+1 blacksmith favor.';
    });
  }

  bool get enemyIsFetalMan {
    return enemyNameIt.contains('Fetale') ||
        enemyNameEn.contains('Fetal') ||
        enemyParty.any((enemy) => enemy.fetal);
  }

  void fleeCombat() {
    if (!inCombat || gameOver) return;
    setState(() {
      clearChoices();
      if (enemyIsBoss) {
        if (enemyNameIt.contains('Baghest')) {
          final roll = _random.nextInt(100) + 1;
          if (roll <= 69) {
            activeAllies.clear();
            clearPosteaEliteGuardState();
            playerHp = max(1, playerHp - max(12, enemyAttack));
            textIt =
                'Provi a fuggire da Baghest. La corruzione ringhia e divora i tuoi compagni.';
            textEn =
                'You try to flee Baghest. Corruption snarls and devours your companions.';
            _savePermanentProgress();
          } else if (roll <= 81) {
            playerHp = 0;
            textIt =
                'Provi a fuggire da Baghest. I tuoi compagni ti fermano prima che tu diventi altro.';
            textEn =
                'You try to flee Baghest. Your companions stop you before you become something else.';
            if (!tryConsumeRebirthBlessing()) finishRun(victorious: false);
          } else {
            final damage = max(10, enemyAttack + currentFloor * 3);
            playerHp = max(0, playerHp - damage).toInt();
            textIt =
                'Baghest ti confonde. Resti nel fight e subisci $damage danni.';
            textEn =
                'Baghest confuses you. You remain in the fight and take $damage damage.';
            if (playerHp <= 0 && !tryConsumeRebirthBlessing()) {
              finishRun(victorious: false);
            }
          }
          return;
        }

        final bossStrike = max(
          10,
          enemyAttack + currentFloor * 4 - totalDefense ~/ 5,
        );
        playerHp = max(0, playerHp - bossStrike).toInt();
        textIt =
            'Il boss non permette la fuga. Ti colpisce mentre indietreggi: $bossStrike danni.';
        textEn =
            'The boss does not allow fleeing. It strikes as you step back: $bossStrike damage.';
        if (playerHp <= 0 && !tryConsumeRebirthBlessing()) {
          finishRun(victorious: false);
        }
        return;
      }

      if (enemyIsFetalMan) {
        var criticalBackstab = max(
          8,
          (enemyAttack * 2.25).round() - totalDefense ~/ 4,
        );
        var criticalShieldNoteIt = '';
        var criticalShieldNoteEn = '';
        if (criticalShieldActive) {
          criticalBackstab = max(1, (criticalBackstab / 2).ceil()).toInt();
          criticalShieldActive = false;
          criticalShieldBlocks++;
          completeAchievement('critical_shield_broken');
          criticalShieldNoteIt =
              '\nScudo Critico: divide il danno e si spezza.';
          criticalShieldNoteEn =
              '\nCritical Shield: divides the damage and breaks.';
        }
        playerHp = max(0, playerHp - criticalBackstab).toInt();
        textIt =
            'Provi a fuggire.\n\n'
            'L’Uomo in Posizione Fetale ti insegue senza alzarsi davvero.\n'
            'Ti raggiunge alle spalle e ti piega il respiro.\n\n'
            'Danno critico alle spalle: $criticalBackstab.\n'
            'Non sei riuscito a scappare.'
            '$criticalShieldNoteIt';
        textEn =
            'You try to flee.\n\n'
            'The Man in Fetal Position chases you without truly standing up.\n'
            'He reaches your back and folds your breath.\n\n'
            'Critical back damage: $criticalBackstab.\n'
            'You failed to escape.'
            '$criticalShieldNoteEn';
        if (playerHp <= 0 && !tryConsumeRebirthBlessing()) {
          finishRun(victorious: false);
        } else {
          completeAchievement('fetal_survivor');
        }
        return;
      }

      final escapeRoll =
          _random.nextInt(100) + 1 + totalVc ~/ 2 + dodgeCharges * 8;
      final escapeDc =
          42 +
          currentFloor * 3 +
          (enemyIsBoss
              ? 35
              : enemyIsElite
              ? 15
              : 0);
      if (escapeRoll >= escapeDc) {
        inCombat = false;
        enemyHp = 0;
        enemyParty.clear();
        syncPrimaryEnemyFromParty();
        textIt =
            'Fuggi dal fight. Il dungeon ti lascia passare, ma segna il tuo odore.';
        textEn =
            'You flee the fight. The dungeon lets you pass, but marks your scent.';
      } else {
        final damage = max(3, enemyAttack + currentFloor - totalDefense ~/ 5);
        playerHp = max(0, playerHp - damage).toInt();
        textIt = 'La fuga fallisce. Subisci $damage danni mentre ti volti.';
        textEn =
            'The escape fails. You take $damage damage while turning away.';
        if (playerHp <= 0 && !tryConsumeRebirthBlessing()) {
          finishRun(victorious: false);
        }
      }
    });
  }

  void restShort() {
    if (!runActive || inCombat || gameOver || restActionUsedThisRoom) return;

    setState(() {
      restActionUsedThisRoom = true;

      if (levelUpRestAvailable) {
        levelUpRestAvailable = false;

        final fullCharges = max(3, 3 + totalOculum + dungeonLevel ~/ 2);
        final halfCharges = max(1, (fullCharges / 2).ceil()).toInt();
        final halfHp = max(1, (playerMaxHp / 2).ceil()).toInt();

        final oldHp = playerHp;
        final oldOculum = oculumCharges;
        final restoredStats = restoreSpentRunStats(full: false);

        playerHp = max(playerHp, halfHp);
        oculumCharges = max(oculumCharges, halfCharges);

        textIt =
            'Riposo da level up.\n\n'
            'Vita almeno a metà: $oldHp → $playerHp/$playerMaxHp\n'
            'Oculum almeno a metà: $oldOculum → $oculumCharges/$fullCharges\n\n'
            'Hai consumato il riposo della stanza.'
            '${spentStatsRestoreLineIt(restoredStats)}';
        textEn =
            'Level up rest.\n\n'
            'HP at least half: $oldHp → $playerHp/$playerMaxHp\n'
            'Oculum at least half: $oldOculum → $oculumCharges/$fullCharges\n\n'
            'You consumed this room rest.'
            '${spentStatsRestoreLineEn(restoredStats)}';
        return;
      }

      final heal = 10 + totalOculum + skillEventBonus('rest');
      final shieldGain = 4 + currentFloor;
      final restoredStats = restoreSpentRunStats(full: false);

      playerHp = min(playerMaxHp, playerHp + heal);
      gainPlayerShield(shieldGain);

      textIt =
          'Riposo breve.\n'
          '+$heal HP\n'
          '+$shieldGain Scudo.'
          '${spentStatsRestoreLineIt(restoredStats)}\n\n'
          'Hai già riposato in questa stanza: dovrai esplorare per riposare di nuovo.';
      textEn =
          'Short rest.\n'
          '+$heal HP\n'
          '+$shieldGain Shield.'
          '${spentStatsRestoreLineEn(restoredStats)}\n\n'
          'You already rested in this room: you must explore before resting again.';
    });
  }

  void useReactionDefense() {
    if (!reactionAvailable || !canUseCombatInput) return;
    setState(() {
      reactionAvailable = false;
      final shield = 20 + totalDefense ~/ 2 + skillEventBonus('defense');
      gainPlayerShield(shield);
      textIt = 'Reazione difensiva.\n+$shield Scudo.';
      textEn = 'Defensive reaction.\n+$shield Shield.';
    });
  }

  void useReactionCounter() {
    if (!reactionAvailable || !canUseCombatInput) return;
    setState(() {
      reactionAvailable = false;
      final damage = max(
        1,
        totalDamage ~/ 2 + totalOculum + skillEventBonus('combat'),
      );
      final target = firstAliveEnemy();
      if (target != null) {
        target.hp = max(0, target.hp - damage).toInt();
        textIt = 'Counter Oculiano.\n$damage danni a ${target.nameIt}.';
        textEn = 'Oculian counter.\n$damage damage to ${target.nameEn}.';
        defeatDeadEnemiesFromParty();
        if (enemyParty.isEmpty) {
          completeCombatVictory();
          return;
        }
        syncPrimaryEnemyFromParty();
      } else {
        enemyHp = max(0, enemyHp - damage).toInt();
      }
    });
  }

  void winRun() {
    finishRun(victorious: true);
  }

  void gainOculumCharges(int amount) {
    oculumMaxCharges += max(0, amount);
    oculumCharges = min(oculumMaxCharges, oculumCharges + max(0, amount));
  }

  bool tryConsumeRebirthBlessing() {
    if (!rebirthBlessingActive || playerHp > 0) return false;

    rebirthBlessingActive = false;
    final previousMaxOculum = max(1, oculumMaxCharges);
    playerHp = playerMaxHp;
    oculumMaxCharges = previousMaxOculum * 3;
    oculumCharges = oculumMaxCharges;
    runCritBonus += 18;
    runDamageBonus += 6;
    runBoons.add('post_rebirth_lethal');
    final restored = playerHp;
    gainPlayerShield(10 + dungeonLevel * 2);
    addLog(
      t(
        'Rinascita attivata: HP ripristinati a $restored.',
        'Rebirth activated: HP restored to $restored.',
      ),
    );
    return true;
  }

  void finishRun({required bool victorious}) {
    clearRunCheckpoint();
    if (endRunOculumPaid) return;
    endRunOculumPaid = true;
    victory = victorious;
    gameOver = true;
    runActive = false;
    inCombat = false;
    enemyTurnPending = false;
    valleyTrainingActive = false;
    valleyTrainingTurnsLeft = 0;
    valleyTurnsLeft = 0;
    valleyHp = 0;
    valleyBloomGuards = 0;
    if (gufusUsedThisRun ||
        activeAllies.any((npc) => npc.id == 'gufus_leviante')) {
      gufusUsedInPreviousRun = true;
    }
    gufusUsedThisRun = false;
    posteaGufusEventActive = false;
    posteaGufusEventPhase = '';
    posteaScientistTurnCounter = 0;
    monsterVillageFightActive = false;
    spentRunResilienza = 0;
    spentRunVolonta = 0;
    spentRunMateria = 0;
    spentRunOculum = 0;

    if (victorious && currentFloor >= 12) {
      evolvePrincipianteForCurrentFloor(completedFloor12: true);
    }

    final progressFloor = currentFloor.clamp(1, maxFloors).toInt();
    final progressRooms = room.clamp(0, maxRooms).toInt();
    final spentGain = max(
      1,
      progressFloor * 2 +
          progressRooms ~/ max(1, roomsPerFloor) +
          (victorious ? 10 : 0),
    ).toInt();
    oculumSpento += spentGain;
    _savePermanentProgress();
    activeAllies
      ..clear()
      ..addAll(_goodNpcs.where((npc) => selectedAllyIds.contains(npc.id)));
    if (posteaEliteGuardInParty) {
      activatePosteaEliteGuard(refill: true);
    } else {
      clearPosteaEliteGuardState();
    }

    final finalObser = victorious
        ? 18 + progressFloor * 2 + killStreak
        : progressFloor + killStreak ~/ 2;
    final finalDust = victorious ? 4 + progressFloor ~/ 2 : progressFloor ~/ 3;
    obserInRun += finalObser;
    ascensionDustInRun += finalDust;

    if (tutorialRunActive && !hasNoviceAchievement) {
      completeAchievement('novice_gate');
      unlockNoviceRewards();
    }

    if (victorious) {
      completeAchievement('run_victory');
    }

    widget.onReward(
      obser: obserInRun,
      ascensionDust: ascensionDustInRun,
      log:
          'Oculum Dungeon ${victorious ? 'cleared' : 'ended'}: +$obserInRun Obser, +$ascensionDustInRun Dust.',
    );

    clearChoices();
    textIt = victorious
        ? 'Vittoria.\n\nIl dungeon apre l’occhio e poi lo chiude piano.\n+$spentGain Oculum Spento.\nRicompensa finale: $obserInRun Obser, $ascensionDustInRun Dust.'
        : 'Run terminata.\n\nIl dungeon chiude la palpebra, ma qualcosa resta freddo tra le dita.\n+$spentGain Oculum Spento.\nRicompensa salvata: $obserInRun Obser, $ascensionDustInRun Dust.';
    textEn = victorious
        ? 'Victory.\n\nThe dungeon opens its eye and slowly closes it.\n+$spentGain Spent Oculum.\nFinal reward: $obserInRun Obser, $ascensionDustInRun Dust.'
        : 'Run ended.\n\nThe dungeon closes its eyelid, but something cold remains between your fingers.\n+$spentGain Spent Oculum.\nSaved reward: $obserInRun Obser, $ascensionDustInRun Dust.';

    offerOculumSpentoUnlocks();
  }

  void offerOculumSpentoUnlocks() {
    clearChoices(mode: 'unlocks');

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Tema casuale - 3 Oculum Spento',
        labelEn: 'Random theme - 3 Spent Oculum',
        icon: Icons.auto_awesome,
        color: const Color(0xFFB85F93),
        onPressed: unlockRandomThemeWithSpent,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Scegli tema - 6 Oculum Spento',
        labelEn: 'Choose theme - 6 Spent Oculum',
        icon: Icons.palette,
        color: const Color(0xFF78CFFF),
        onPressed: showSpecificThemeUnlockChoices,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Art casuale — 6 Oculum Spento',
        labelEn: 'Random Art — 6 Spent Oculum',
        icon: Icons.casino,
        color: const Color(0xFF8B5CF6),
        onPressed: unlockRandomArtWithSpent,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Scegli Art specifica — 11 Oculum Spento',
        labelEn: 'Choose specific Art — 11 Spent Oculum',
        icon: Icons.visibility,
        color: const Color(0xFFA78BFA),
        onPressed: showSpecificArtUnlockChoices,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Arma casuale — 5 Oculum Spento',
        labelEn: 'Random Weapon — 5 Spent Oculum',
        icon: Icons.casino,
        color: const Color(0xFFFFD36A),
        onPressed: unlockRandomWeaponWithSpent,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Scegli arma specifica — 9 Oculum Spento',
        labelEn: 'Choose specific weapon — 9 Spent Oculum',
        icon: Icons.hardware,
        color: const Color(0xFFFFB020),
        onPressed: showSpecificWeaponUnlockChoices,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Cancella save permanente',
        labelEn: 'Delete permanent save',
        icon: Icons.delete_forever,
        color: Colors.redAccent,
        onPressed: showDeleteSaveConfirm,
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Torna al dungeon',
        labelEn: 'Back to dungeon',
        icon: Icons.keyboard_return,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt =
                'Sblocchi chiusi.\n\n'
                'Oculum Spento disponibile: $oculumSpento.';
            textEn =
                'Unlocks closed.\n\n'
                'Available Spent Oculum: $oculumSpento.';
          });
        },
      ),
    );
  }

  void showUnlockHub() {
    setState(() {
      final lockedThemes = lockedThemeUnlocks().length;
      textIt =
          'Camera degli Sblocchi.\n\n'
          'Oculum Spento disponibile: $oculumSpento.\n\n'
          'Puoi sbloccare temi, Art e armi.\n'
          'Temi ancora acquistabili: $lockedThemes.\n'
          'I Titoli non si comprano qui: appaiono solo durante la run o dagli achievement.\n'
          'Le Art e le armi sbloccate entrano nelle scelte iniziali randomiche delle prossime run.';
      textEn =
          'Unlock Chamber.\n\n'
          'Available Spent Oculum: $oculumSpento.\n\n'
          'You can unlock themes, Arts and weapons.\n'
          'Themes still purchasable: $lockedThemes.\n'
          'Titles are not bought here: they appear only during the run or from achievements.\n'
          'Unlocked Arts and weapons enter the random starting choices of future runs.';

      offerOculumSpentoUnlocks();
    });
  }

  bool isDungeonThemeUnlocked(String id) {
    return unlockedThemePresetIds.contains(id) ||
        widget.initialUnlockedThemePresetIds.contains(id);
  }

  List<_DungeonThemeUnlockDef> lockedThemeUnlocks() {
    return _themeUnlocks
        .where((theme) => !isDungeonThemeUnlocked(theme.id))
        .toList();
  }

  void unlockRandomThemeWithSpent() {
    setState(() {
      if (oculumSpento < 3) {
        textIt = 'Oculum Spento insufficiente. Te ne servono 3.';
        textEn = 'Not enough Spent Oculum. You need 3.';
        return;
      }

      final locked = lockedThemeUnlocks();
      if (locked.isEmpty) {
        textIt = 'Hai gia sbloccato tutti i temi acquistabili dal dungeon.';
        textEn = 'You already unlocked every dungeon-purchasable theme.';
        return;
      }

      oculumSpento -= 3;
      final theme = locked[_random.nextInt(locked.length)];
      unlockedThemePresetIds.add(theme.id);
      widget.onThemeUnlocked?.call(theme.id);
      _savePermanentProgress();
      offerOculumSpentoUnlocks();

      textIt =
          'Tema casuale sbloccato:\n${theme.nameIt}\n\nOculum Spento rimasto: $oculumSpento.';
      textEn =
          'Random theme unlocked:\n${theme.nameEn}\n\nSpent Oculum left: $oculumSpento.';
    });
  }

  void showSpecificThemeUnlockChoices() {
    setState(() {
      clearChoices(mode: 'unlocks');
      final locked = lockedThemeUnlocks()..shuffle(_random);
      textIt =
          'Scegli un tema specifico da sbloccare.\n\nCosto: 6 Oculum Spento.';
      textEn = 'Choose a specific theme to unlock.\n\nCost: 6 Spent Oculum.';

      if (locked.isEmpty) {
        textIt = 'Hai gia sbloccato tutti i temi acquistabili dal dungeon.';
        textEn = 'You already unlocked every dungeon-purchasable theme.';
        offerOculumSpentoUnlocks();
        return;
      }

      for (final theme in locked) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: theme.nameIt,
            labelEn: theme.nameEn,
            icon: theme.id == 'phobia_dark'
                ? Icons.visibility_off
                : Icons.palette,
            color: theme.color,
            onPressed: () => unlockSpecificThemeWithSpent(theme),
          ),
        );
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Indietro',
          labelEn: 'Back',
          icon: Icons.arrow_back,
          color: Colors.blueGrey,
          onPressed: showUnlockHub,
        ),
      );
    });
  }

  void unlockSpecificThemeWithSpent(_DungeonThemeUnlockDef theme) {
    setState(() {
      if (isDungeonThemeUnlocked(theme.id)) {
        textIt = 'Tema gia sbloccato: ${theme.nameIt}.';
        textEn = 'Theme already unlocked: ${theme.nameEn}.';
        return;
      }
      if (oculumSpento < 6) {
        textIt = 'Oculum Spento insufficiente. Te ne servono 6.';
        textEn = 'Not enough Spent Oculum. You need 6.';
        return;
      }

      oculumSpento -= 6;
      unlockedThemePresetIds.add(theme.id);
      widget.onThemeUnlocked?.call(theme.id);
      _savePermanentProgress();
      clearChoices();
      offerOculumSpentoUnlocks();

      textIt =
          'Tema specifico sbloccato:\n${theme.nameIt}\n\nOculum Spento rimasto: $oculumSpento.';
      textEn =
          'Specific theme unlocked:\n${theme.nameEn}\n\nSpent Oculum left: $oculumSpento.';
    });
  }

  void unlockRandomArtWithSpent() {
    setState(() {
      if (oculumSpento < 6) {
        textIt = 'Oculum Spento insufficiente. Te ne servono 6.';
        textEn = 'Not enough Spent Oculum. You need 6.';
        return;
      }
      final locked = _allArts
          .where((a) => isArtUnlockableOutsideLateGame(a))
          .where((a) => !unlockedArtIds.contains(a.effectId))
          .toList();
      if (locked.isEmpty) return;
      oculumSpento -= 6;
      final art = locked[_random.nextInt(locked.length)];
      unlockedArtIds.add(art.effectId);
      _savePermanentProgress();
      offerOculumSpentoUnlocks();
      textIt =
          'Art casuale sbloccata:\n${art.nameIt}\n\nOculum Spento rimasto: $oculumSpento.';
      textEn =
          'Random Art unlocked:\n${art.nameEn}\n\nSpent Oculum left: $oculumSpento.';
    });
  }

  void showSpecificArtUnlockChoices() {
    setState(() {
      clearChoices(mode: 'unlocks');
      final locked =
          _allArts
              .where((a) => isArtUnlockableOutsideLateGame(a))
              .where((a) => !unlockedArtIds.contains(a.effectId))
              .toList()
            ..shuffle(_random);
      textIt = 'Scegli una Art specifica da sbloccare. Costa 11 Oculum Spento.';
      textEn = 'Choose a specific Art to unlock. It costs 11 Spent Oculum.';
      for (final art in locked.take(12)) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: art.nameIt,
            labelEn: art.nameEn,
            icon: Icons.visibility,
            color: elementColor(art.elementId),
            onPressed: () => unlockSpecificArtWithSpent(art),
          ),
        );
      }
    });
  }

  void unlockSpecificArtWithSpent(_DungeonArt art) {
    setState(() {
      if (isLateGameOnlyArtId(art.effectId)) {
        textIt =
            'Mille Fuochi non può essere sbloccata qui.\n'
            'È una Art finale e appare solo nelle ultime 16 stanze.';
        textEn =
            'Thousand Fires cannot be unlocked here.\n'
            'It is a final Art and appears only in the last 16 rooms.';
        return;
      }

      if (oculumSpento < 11) {
        textIt = 'Oculum Spento insufficiente. Te ne servono 11.';
        textEn = 'Not enough Spent Oculum. You need 11.';
        return;
      }
      oculumSpento -= 11;
      unlockedArtIds.add(art.effectId);
      _savePermanentProgress();
      clearChoices();
      offerOculumSpentoUnlocks();
      textIt =
          'Art specifica sbloccata:\n${art.nameIt}\n\nOculum Spento rimasto: $oculumSpento.';
      textEn =
          'Specific Art unlocked:\n${art.nameEn}\n\nSpent Oculum left: $oculumSpento.';
    });
  }

  void unlockRandomWeaponWithSpent() {
    setState(() {
      if (oculumSpento < 5) {
        textIt = 'Oculum Spento insufficiente. Te ne servono 5.';
        textEn = 'Not enough Spent Oculum. You need 5.';
        return;
      }

      final locked = _starterWeapons
          .where(
            (weapon) =>
                !unlockedWeaponIds.contains(weapon.id) &&
                !isStoryLockedWeaponId(weapon.id),
          )
          .toList();

      if (locked.isEmpty) {
        textIt = 'Hai già sbloccato tutte le armi iniziali.';
        textEn = 'You already unlocked every starting weapon.';
        return;
      }

      oculumSpento -= 5;
      final weapon = locked[_random.nextInt(locked.length)];
      unlockedWeaponIds.add(weapon.id);
      _savePermanentProgress();

      clearChoices();
      offerOculumSpentoUnlocks();

      textIt =
          'Arma casuale sbloccata:\n'
          '${weapon.nameIt}\n\n'
          '${weapon.descIt}\n\n'
          'Oculum Spento rimasto: $oculumSpento.';
      textEn =
          'Random weapon unlocked:\n'
          '${weapon.nameEn}\n\n'
          '${weapon.descEn}\n\n'
          'Spent Oculum left: $oculumSpento.';
    });
  }

  void showSpecificWeaponUnlockChoices() {
    setState(() {
      clearChoices(mode: 'unlocks');

      final locked =
          _starterWeapons
              .where(
                (weapon) =>
                    !unlockedWeaponIds.contains(weapon.id) &&
                    !isStoryLockedWeaponId(weapon.id),
              )
              .toList()
            ..shuffle(_random);

      textIt =
          'Scegli un’arma specifica da sbloccare.\n\n'
          'Costo: 9 Oculum Spento.\n'
          'Le armi sbloccate appariranno tra le 3 scelte randomiche a inizio run.';
      textEn =
          'Choose a specific weapon to unlock.\n\n'
          'Cost: 9 Spent Oculum.\n'
          'Unlocked weapons will appear among the 3 random starting choices.';

      if (locked.isEmpty) {
        textIt = 'Hai già sbloccato tutte le armi iniziali.';
        textEn = 'You already unlocked every starting weapon.';
        offerOculumSpentoUnlocks();
        return;
      }

      for (final weapon in locked.take(12)) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: weapon.nameIt,
            labelEn: weapon.nameEn,
            icon: Icons.hardware,
            color: elementColor(weapon.elementId),
            onPressed: () => unlockSpecificWeaponWithSpent(weapon),
          ),
        );
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Indietro',
          labelEn: 'Back',
          icon: Icons.arrow_back,
          color: Colors.blueGrey,
          onPressed: showUnlockHub,
        ),
      );
    });
  }

  void unlockSpecificWeaponWithSpent(_StarterWeapon weapon) {
    setState(() {
      if (oculumSpento < 9) {
        textIt = 'Oculum Spento insufficiente. Te ne servono 9.';
        textEn = 'Not enough Spent Oculum. You need 9.';
        return;
      }

      oculumSpento -= 9;
      unlockedWeaponIds.add(weapon.id);
      _savePermanentProgress();

      clearChoices();
      offerOculumSpentoUnlocks();

      textIt =
          'Arma specifica sbloccata:\n'
          '${weapon.nameIt}\n\n'
          '${weapon.descIt}\n\n'
          'Oculum Spento rimasto: $oculumSpento.';
      textEn =
          'Specific weapon unlocked:\n'
          '${weapon.nameEn}\n\n'
          '${weapon.descEn}\n\n'
          'Spent Oculum left: $oculumSpento.';
    });
  }

  _AchievementDef? achievementById(String id) {
    for (final achievement in _achievements) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  _GoodNpc? npcById(String id) {
    for (final npc in _goodNpcs) {
      if (npc.id == id) return npc;
    }
    return null;
  }

  void unlockNoviceRewards() {
    for (var i = 0; i < 3; i++) {
      tryUnlockRandomWeapon();
      tryUnlockRandomArt();
    }
    _savePermanentProgress();
  }

  String? themePresetForAchievement(String id) {
    switch (id) {
      case 'first_blood':
      case 'first_boss':
      case 'baghest_costume_unlocked':
      case 'baghest_eye_relic_unlocked':
        return 'blood_court';
      case 'floor_zero_clear':
      case 'drop_scholar':
      case 'converted_drops':
        return 'ash_oracle';
      case 'peaceful_monsters_kooba':
      case 'party_two':
        return 'monster_lantern';
      case 'evonest_proof':
      case 'drowned_magic':
        return 'witch_glass';
      case 'postea_coin':
      case 'postea_scientist_unlocked':
      case 'postea_gufus_rescue':
      case 'postea_valley_smile':
      case 'postea_leviante_genes':
        return 'postea_bloom';
      case 'floor_nine':
      case 'floor_nine_moon':
      case 'lunium_costume_unlocked':
      case 'vapium_costume_unlocked':
        return 'moon_iron';
      case 'run_victory':
      case 'oculum_expert':
      case 'title_level_xii':
      case 'mille_fuochi_used':
        return 'void_liturgy';
    }
    return null;
  }

  void notifyThemeUnlockForAchievement(String id) {
    final presetId = themePresetForAchievement(id);
    if (presetId == null) return;
    widget.onThemeUnlocked?.call(presetId);
  }

  void notifyLoadedThemeUnlocks() {
    final presets = <String>{};
    for (final id in completedAchievementIds) {
      final presetId = themePresetForAchievement(id);
      if (presetId != null) presets.add(presetId);
    }
    presets.addAll(unlockedThemePresetIds);
    for (final presetId in presets) {
      widget.onThemeUnlocked?.call(presetId);
    }
  }

  void completeAchievement(String id) {
    if (id == 'mille_fuochi_unlocked' && runCount <= 1) {
      addLog(
        t(
          'Mille Fuochi non si sblocca nella prima run.',
          'Thousand Fires does not unlock during the first run.',
        ),
      );
      return;
    }
    if (completedAchievementIds.contains(id)) return;

    final achievement = achievementById(id);
    if (achievement == null) return;

    completedAchievementIds.add(id);

    switch (achievement.rewardType) {
      case 'npc':
        unlockedNpcIds.add(achievement.rewardId);
        autoBringNpcRewardIfPossible(achievement.rewardId);
        break;

      case 'weapon':
        unlockedWeaponIds.add(achievement.rewardId);
        break;

      case 'costume':
        unlockedCostumeIds.add(achievement.rewardId);
        break;

      case 'art':
        if (!isLateGameOnlyArtId(achievement.rewardId)) {
          unlockedArtIds.add(achievement.rewardId);
        }
        break;

      case 'relic':
        unlockedRelicIds.add(achievement.rewardId);
        if (id == 'hoshy_relic_unlocked') {
          unlockedArtIds.add('hoshy_oculum_art');
        }
        break;

      case 'title':
        if (achievement.rewardId == 'random') {
          unlockRandomTitle();
        } else {
          unlockedTitleIds.add(achievement.rewardId);
          titleLevels[achievement.rewardId] = max(
            1,
            titleLevels[achievement.rewardId] ?? 1,
          ).toInt();
        }
        break;

      case 'random_art':
        final locked = _allArts
            .where(
              (art) =>
                  !art.unlockedByDefault &&
                  !unlockedArtIds.contains(art.effectId) &&
                  (achievement.rewardId == 'any' ||
                      art.elementId == achievement.rewardId),
            )
            .toList();

        if (locked.isNotEmpty) {
          final art = locked[_random.nextInt(locked.length)];
          unlockedArtIds.add(art.effectId);
        }
        break;

      case 'oculum':
        oculumSpento += int.tryParse(achievement.rewardId) ?? 0;
        break;
    }

    _savePermanentProgress();
    notifyThemeUnlockForAchievement(id);

    addLog(
      t(
        'Achievement completato: ${achievement.titleIt} → ${achievement.rewardIt}.',
        'Achievement completed: ${achievement.titleEn} → ${achievement.rewardEn}.',
      ),
    );
  }

  void repairCompletedAchievementRewards() {
    var changed = false;

    for (final id in completedAchievementIds.toList()) {
      final achievement = achievementById(id);
      if (achievement == null) continue;

      switch (achievement.rewardType) {
        case 'npc':
          if (!unlockedNpcIds.contains(achievement.rewardId)) {
            unlockedNpcIds.add(achievement.rewardId);
            changed = true;
          }
          break;

        case 'weapon':
          if (!unlockedWeaponIds.contains(achievement.rewardId)) {
            unlockedWeaponIds.add(achievement.rewardId);
            changed = true;
          }
          break;

        case 'costume':
          if (!unlockedCostumeIds.contains(achievement.rewardId)) {
            unlockedCostumeIds.add(achievement.rewardId);
            changed = true;
          }
          break;

        case 'art':
          if (!isLateGameOnlyArtId(achievement.rewardId) &&
              !unlockedArtIds.contains(achievement.rewardId)) {
            unlockedArtIds.add(achievement.rewardId);
            changed = true;
          }
          break;
        case 'relic':
          if (!unlockedRelicIds.contains(achievement.rewardId)) {
            unlockedRelicIds.add(achievement.rewardId);
            changed = true;
          }
          if (id == 'hoshy_relic_unlocked' &&
              !unlockedArtIds.contains('hoshy_oculum_art')) {
            unlockedArtIds.add('hoshy_oculum_art');
            changed = true;
          }
          break;
        case 'title':
          if (achievement.rewardId != 'random' &&
              !unlockedTitleIds.contains(achievement.rewardId)) {
            unlockedTitleIds.add(achievement.rewardId);
            titleLevels[achievement.rewardId] = max(
              1,
              titleLevels[achievement.rewardId] ?? 1,
            ).toInt();
            changed = true;
          }
          break;
      }
    }

    if (completedAchievementIds.contains('postea_gufus_rescue')) {
      if (!posteaGufusEventCompleted) {
        posteaGufusEventCompleted = true;
        changed = true;
      }
      changed = unlockedWeaponIds.add('postea_auto_rifle') || changed;
      changed = unlockedWeaponIds.add('postea_grenades') || changed;
      changed = unlockedCostumeIds.add('postea_elite_armor') || changed;
      changed = unlockedNpcIds.add('postea_elite_guard') || changed;
    }

    if (changed) _savePermanentProgress();
  }

  int principianteTargetLevel({bool completedFloor12 = false}) {
    if (completedFloor12) return 12;
    if (currentFloor <= 0) return 1;
    return currentFloor.clamp(1, 12).toInt();
  }

  void evolvePrincipianteForCurrentFloor({bool completedFloor12 = false}) {
    if (!unlockedTitleIds.contains('principiante')) return;

    final target = principianteTargetLevel(completedFloor12: completedFloor12);
    final current = titleLevel('principiante');

    if (target <= current) return;

    for (var lvl = current + 1; lvl <= target; lvl++) {
      titleLevels['principiante'] = lvl;
      unlockPrincipianteLevelReward(lvl);
      lastPrincipianteEvolutionLevel = lvl;
      addLog(
        t(
          'Principiante evolve: ${principianteNameIt(lvl)} Lv.$lvl.',
          'Beginner evolves: ${principianteNameEn(lvl)} Lv.$lvl.',
        ),
      );
    }

    if (target >= 12) {
      completeAchievement('oculum_expert');
      unlockOculumExpertPack();
    }

    _savePermanentProgress();
  }

  void unlockPrincipianteLevelReward(int level) {
    switch (level) {
      case 2:
        runDamageBonus += 1;
        break;
      case 3:
        unlockRandomTitle();
        break;
      case 4:
        tryUnlockRandomWeapon();
        break;
      case 5:
        runDefenseBonus += 2;
        break;
      case 6:
        unlockedRelicIds.add('nido_di_muschio');
        break;
      case 7:
        tryUnlockRandomArt();
        break;
      case 8:
        unlockedRelicIds.add('vento_sotto_unghia');
        break;
      case 9:
        unlockRandomTitle();
        break;
      case 10:
        tryUnlockRandomWeapon();
        break;
      case 11:
        unlockedRelicIds.add('sale_delle_ossa');
        break;
      case 12:
        break;
    }
  }

  void unlockOculumExpertPack() {
    if (completedAchievementIds.contains('oculum_expert_pack_claimed')) return;

    completedAchievementIds.add('oculum_expert_pack_claimed');

    for (var i = 1; i <= 36; i++) {
      unlockedArtIds.add('expert_oculum_art_$i');
    }

    unlockedWeaponIds.addAll({
      'expert_oculum_scythe',
      'expert_pupil_maul',
      'expert_star_chakram',
      'expert_core_rapier',
      'expert_moon_flail',
      'expert_obser_boomerang',
    });

    unlockedTitleIds.addAll({
      'esperto_di_oculum',
      'archivista_dei_piani',
      'lama_delle_dodici_palpebre',
      'cuore_del_core_viola',
    });

    titleLevels['esperto_di_oculum'] = max(
      1,
      titleLevels['esperto_di_oculum'] ?? 1,
    ).toInt();

    unlockedRelicIds.addAll({
      'nido_di_muschio',
      'luna_lattea',
      'stella_spina',
      'brace_bambina',
      'vaso_dei_morti_piccoli',
      'acqua_senza_gola',
      'vento_sotto_unghia',
      'sale_delle_ossa',
    });

    obserInRun += 36;
    ascensionDustInRun += 12;
    oculumSpento += 12;

    addLog(
      t(
        'Pack Esperto di Oculum sbloccato: 36 Art, armi, Titoli, reliquie ed eventi.',
        'Oculum Expert pack unlocked: 36 Arts, weapons, Titles, relics and events.',
      ),
    );
  }

  bool tryExpertOculumEvent() {
    if (!completedAchievementIds.contains('oculum_expert')) return false;
    if (inCombat || gameOver || currentFloor < 2) return false;
    if (!chance(5 + currentFloor)) return false;

    clearChoices(mode: 'event');
    final rewardRoll = _random.nextInt(3);

    if (rewardRoll == 0) {
      final shield = 36 + currentFloor * 4;
      gainPlayerShield(shield);
      textIt =
          'Evento Esperto di Oculum.\n\nUna palpebra esperta si chiude davanti a te.\n+$shield Scudo.';
      textEn =
          'Oculum Expert Event.\n\nAn expert eyelid closes before you.\n+$shield Shield.';
    } else if (rewardRoll == 1) {
      gainOculumCharges(1);
      runCritBonus += 6;
      textIt =
          'Evento Esperto di Oculum.\n\nUn occhio senza corpo ti corregge il respiro.\n+1 Oculum massimo e +6 critico.';
      textEn =
          'Oculum Expert Event.\n\nA bodiless eye corrects your breath.\n+1 max Oculum and +6 critical.';
    } else {
      final title = unlockRandomTitle();
      textIt =
          'Evento Esperto di Oculum.\n\nUn titolo cade come una ciglia antica.\n${titleNameIt(title)} Lv.${titleLevel(title.id)}.';
      textEn =
          'Oculum Expert Event.\n\nA title falls like an ancient eyelash.\n${titleNameEn(title)} Lv.${titleLevel(title.id)}.';
    }

    return true;
  }

  void checkPassiveAchievements() {
    if (killStreak >= 1) completeAchievement('first_blood');
    if (currentFloor >= 3) {
      completeAchievement('floor_three_title');
      completeAchievement('rebirth_seed_relic_unlocked');
      if (playerShield >= 50) completeAchievement('pawn_relic_unlocked');
    }
    if (currentFloor >= 6) {
      completeAchievement('floor_six');
      completeAchievement('floor_six_oculian');
      if (!activeAllies.any((npc) => npc.id == 'giant_skull_tavernkeeper')) {
        completeAchievement('skull_hands_relic_unlocked');
      }
    }
    if (currentFloor >= 9) completeAchievement('floor_nine_moon');
    if (currentFloor >= 12) completeAchievement('floor_twelve_end');
    if (aoeCasts >= 5) {
      completeAchievement('aoe_master');
      completeAchievement('hoshy_relic_unlocked');
    }
    if (oculumSkillCasts >= 10) {
      completeAchievement('ten_oculum_skills');
      if (activeArt?.elementId == 'moon' || activeArt?.elementId == 'star') {
        completeAchievement('lunium_costume_unlocked');
      }
    }
    if (oculumSpento >= 20) completeAchievement('oculum_spento_20');
    if (merchantBuys >= 5) {
      completeAchievement('merchant_cards');
      completeAchievement('obser_costume_unlocked');
    }
    if (potionsUsed >= 5) {
      completeAchievement('potion_user');
      completeAchievement('vitalium_costume_unlocked');
    }
    if (dropsStudied >= 5) completeAchievement('drop_scholar');
    if (enemyDropsConverted >= 4) completeAchievement('converted_drops');
    if (currentFloor >= 9) {
      completeAchievement('floor_nine');
      if (playerShield >= 80) completeAchievement('vapium_costume_unlocked');
    }
    if (artTechniqueUses >= 6) {
      completeAchievement('art_technique_user');
      completeAchievement('hoshy_relic_unlocked');
    }
    if (drownedSummonTurns > 0) completeAchievement('drowned_magic');
    if (unlockedWeaponIds.length >= 10) {
      completeAchievement('weapon_collector_10');
    }
    if (unlockedArtIds.length >= 12) completeAchievement('art_collector_12');
    if (activeAllies.length >= 2) completeAchievement('party_two');
    if (positiveTitleEventsSeen >= 3) {
      completeAchievement('title_whisper_three');
      completeAchievement('vervain_relic_unlocked');
    }
    if (blindSpotTitleEventsSeen >= 1) completeAchievement('blind_spot_seen');
    if (titleLevels.values.any((level) => level >= 12)) {
      completeAchievement('title_level_xii');
    }
    if (titleLevel('principiante') >= 12) completeAchievement('oculum_expert');
    if (unlockedTitleIds.length >= 10) {
      completeAchievement('title_collector_10');
    }
    repairCompletedAchievementRewards();
  }

  bool achievementRewardAlreadyApplied(_AchievementDef achievement) {
    switch (achievement.rewardType) {
      case 'npc':
        return unlockedNpcIds.contains(achievement.rewardId);
      case 'weapon':
        return unlockedWeaponIds.contains(achievement.rewardId);
      case 'art':
        if (isLateGameOnlyArtId(achievement.rewardId)) {
          return completedAchievementIds.contains(achievement.id);
        }
        return unlockedArtIds.contains(achievement.rewardId);
      case 'relic':
        return unlockedRelicIds.contains(achievement.rewardId);
      case 'title':
        return achievement.rewardId == 'random' ||
            unlockedTitleIds.contains(achievement.rewardId);
      case 'random_art':
        return true;
      case 'oculum':
        return completedAchievementIds.contains(achievement.id);
      default:
        return completedAchievementIds.contains(achievement.id);
    }
  }

  int get principianteLevelSpentCost {
    final lvl = titleLevel('principiante');
    return 8 + lvl * 3;
  }

  int get randomTitleSpentCost => 7;

  int get specificTitleSpentCost => 13;

  bool canUpgradeAnyTitle() {
    return _allTitles.any((title) => (titleLevels[title.id] ?? 0) < 12);
  }

  String titleBuffTextIt(_TitleDef title) {
    final lvl = titleLevel(title.id);
    final parts = <String>[];

    if (title.res != 0) {
      parts.add('${title.res > 0 ? '+' : ''}${title.res * lvl} Resilienza');
    }
    if (title.vol != 0) {
      parts.add('${title.vol > 0 ? '+' : ''}${title.vol * lvl} Volontà');
    }
    if (title.mat != 0) {
      parts.add('${title.mat > 0 ? '+' : ''}${title.mat * lvl} Materia');
    }
    if (title.ocu != 0) {
      parts.add('${title.ocu > 0 ? '+' : ''}${title.ocu * lvl} Oculum');
    }
    if (title.damage != 0) {
      parts.add('${title.damage > 0 ? '+' : ''}${title.damage * lvl} Danno');
    }
    if (title.defense != 0) {
      parts.add('${title.defense > 0 ? '+' : ''}${title.defense * lvl} Difesa');
    }

    if (title.id == 'principiante') {
      parts.add('Critico: stun/sonno breve');
      parts.add('+20 Scudo');
    }

    if (title.id == 'pelle_di_muschio' || title.id == 'giardino_nel_torace') {
      parts.add('cura esplorando');
    }

    if (title.id == 'ombra_che_ascolta') {
      parts.add('furto vita');
    }

    if (title.id == 'radice_gentile') {
      parts.add('resisti meglio agli attriti piccoli della run');
    }

    if (title.id == 'luna_infranta') {
      parts.add('più Oculum e protezione lunare');
    }

    if (title.id == 'stella_nascosta') {
      parts.add('critici più frequenti e Fato più instabile');
    }

    if (title.id == 'pelle_di_muschio') {
      parts.add('cura esplorando e difesa organica');
    }

    if (title.id == 'corona_di_sale') {
      parts.add('build Volontà/danno, aggressiva e secca');
    }

    if (title.id == 'occhio_del_nido') {
      parts.add('bonus totale, stabile, da build ibrida');
    }

    if (title.id == 'fiato_di_cenere') {
      parts.add('danni e bruciature più cattive');
    }

    if (title.id == 'mano_del_pozzo') {
      parts.add('Materia, controllo e peso');
    }

    if (title.id == 'eco_del_fiore') {
      parts.add('Oculum e micro-cure di esplorazione');
    }

    if (title.id == 'dente_di_stella') {
      parts.add('glass cannon critico');
    }

    if (title.id == 'ombra_che_ascolta') {
      parts.add('furto vita e danno oscuro');
    }

    if (title.id == 'mille_lacrime') {
      parts.add('scudo/Oculum e possibili eventi lacrima');
    }

    if (title.id == 'osso_che_prega') {
      parts.add('tank, evocazioni, core più presenti');
    }

    if (title.id == 'coro_sottopelle') {
      parts.add('critico sonoro e danno instabile');
    }

    if (title.id == 'giardino_nel_torace') {
      parts.add('cura, natura, sopravvivenza lenta');
    }

    if (title.id == 'mano_senza_dito') {
      parts.add('reazioni più utili e danno fisico');
    }

    if (title.id == 'palpebra_di_sale') {
      parts.add('controllo, debuff e miniboss rari');
    }

    if (title.id == 'fame_di_stelle') {
      parts.add('danni enormi ma poca sicurezza');
    }

    if (title.id == 'nervo_di_luna') {
      parts.add('Oculum lunare e Scudo Critico occasionale');
    }

    if (title.id == 'esperto_di_oculum') {
      parts.add('eco delle Open, potere alto e boss più feroci');
    }

    if (title.id == 'archivista_dei_piani') {
      parts.add('eventi più leggibili e ricompense più chiare');
    }

    if (title.id == 'lama_delle_dodici_palpebre') {
      parts.add('offensiva pura da boss killer');
    }

    if (title.id == 'cuore_del_core_viola') {
      parts.add('core viola più generosi e difesa corrotta');
    }

    return parts.isEmpty ? title.descIt : parts.join(', ');
  }

  String titleBuffTextEn(_TitleDef title) {
    final lvl = titleLevel(title.id);
    final parts = <String>[];

    if (title.res != 0) {
      parts.add('${title.res > 0 ? '+' : ''}${title.res * lvl} Resilience');
    }
    if (title.vol != 0) {
      parts.add('${title.vol > 0 ? '+' : ''}${title.vol * lvl} Will');
    }
    if (title.mat != 0) {
      parts.add('${title.mat > 0 ? '+' : ''}${title.mat * lvl} Materia');
    }
    if (title.ocu != 0) {
      parts.add('${title.ocu > 0 ? '+' : ''}${title.ocu * lvl} Oculum');
    }
    if (title.damage != 0) {
      parts.add('${title.damage > 0 ? '+' : ''}${title.damage * lvl} Damage');
    }
    if (title.defense != 0) {
      parts.add(
        '${title.defense > 0 ? '+' : ''}${title.defense * lvl} Defense',
      );
    }

    if (title.id == 'principiante') {
      parts.add('Critical: stun/short sleep');
      parts.add('+20 Shield');
    }

    if (title.id == 'pelle_di_muschio' || title.id == 'giardino_nel_torace') {
      parts.add('healing while exploring');
    }

    if (title.id == 'ombra_che_ascolta') {
      parts.add('lifesteal');
    }

    if (title.id == 'radice_gentile') {
      parts.add('better endurance against small run friction');
    }

    if (title.id == 'luna_infranta') {
      parts.add('more Oculum and lunar protection');
    }

    if (title.id == 'stella_nascosta') {
      parts.add('more critical pressure and unstable Fate');
    }

    if (title.id == 'pelle_di_muschio') {
      parts.add('exploration healing and organic defense');
    }

    if (title.id == 'corona_di_sale') {
      parts.add('Will/damage build, dry and aggressive');
    }

    if (title.id == 'occhio_del_nido') {
      parts.add('stable hybrid all-round bonus');
    }

    if (title.id == 'fiato_di_cenere') {
      parts.add('stronger damage and nastier burns');
    }

    if (title.id == 'mano_del_pozzo') {
      parts.add('Materia, control and weight');
    }

    if (title.id == 'eco_del_fiore') {
      parts.add('Oculum and small exploration heals');
    }

    if (title.id == 'dente_di_stella') {
      parts.add('critical glass cannon');
    }

    if (title.id == 'ombra_che_ascolta') {
      parts.add('lifesteal and shadow damage');
    }

    if (title.id == 'mille_lacrime') {
      parts.add('shield/Oculum and possible tear events');
    }

    if (title.id == 'osso_che_prega') {
      parts.add('tank, summons, more core presence');
    }

    if (title.id == 'coro_sottopelle') {
      parts.add('sound criticals and unstable damage');
    }

    if (title.id == 'giardino_nel_torace') {
      parts.add('healing, nature, slow survival');
    }

    if (title.id == 'mano_senza_dito') {
      parts.add('better reactions and physical damage');
    }

    if (title.id == 'palpebra_di_sale') {
      parts.add('control, debuff and rare minibosses');
    }

    if (title.id == 'fame_di_stelle') {
      parts.add('huge damage but little safety');
    }

    if (title.id == 'nervo_di_luna') {
      parts.add('lunar Oculum and occasional Critical Shield');
    }

    if (title.id == 'esperto_di_oculum') {
      parts.add('Open echoes, high power and fiercer bosses');
    }

    if (title.id == 'archivista_dei_piani') {
      parts.add('clearer events and more readable rewards');
    }

    if (title.id == 'lama_delle_dodici_palpebre') {
      parts.add('pure offense boss-killer');
    }

    if (title.id == 'cuore_del_core_viola') {
      parts.add('more generous purple cores and corrupted defense');
    }

    return parts.isEmpty ? title.descEn : parts.join(', ');
  }

  String titleDetailIt(_TitleDef title) {
    return '${titleNameIt(title)} Lv.${titleLevel(title.id)}\n\n'
        '[Buff]\n'
        '${titleBuffTextIt(title)}\n\n'
        '[Punto Cieco]\n'
        '${title.blindSpotIt}\n\n'
        '[Descrizione]\n'
        '${title.descIt}';
  }

  String titleDetailEn(_TitleDef title) {
    return '${titleNameEn(title)} Lv.${titleLevel(title.id)}\n\n'
        '[Buff]\n'
        '${titleBuffTextEn(title)}\n\n'
        '[Blind Spot]\n'
        '${title.blindSpotEn}\n\n'
        '[Description]\n'
        '${title.descEn}';
  }

  void levelPrincipianteWithSpent() {
    setState(() {
      unlockedTitleIds.add('principiante');
      equippedTitleIds.add('principiante');

      final current = titleLevel('principiante');
      if (current >= 12) {
        textIt =
            'Principiante è già diventato Esperto di Oculum.\n\n${titleDetailIt(_allTitles.firstWhere((t) => t.id == 'principiante'))}';
        textEn =
            'Beginner has already become Oculum Expert.\n\n${titleDetailEn(_allTitles.firstWhere((t) => t.id == 'principiante'))}';
        return;
      }

      if (oculumSpento < principianteLevelSpentCost) {
        textIt =
            'Oculum Spento insufficiente.\n'
            'Costo evoluzione Principiante: $principianteLevelSpentCost.\n'
            'Disponibile: $oculumSpento.';
        textEn =
            'Not enough Spent Oculum.\n'
            'Beginner evolution cost: $principianteLevelSpentCost.\n'
            'Available: $oculumSpento.';
        return;
      }

      oculumSpento -= principianteLevelSpentCost;
      titleLevels['principiante'] = min(12, current + 1).toInt();

      if (titleLevel('principiante') >= 12) {
        completeAchievement('oculum_expert');
        unlockOculumExpertPack();
      }

      _savePermanentProgress();

      final principiante = _allTitles.firstWhere((t) => t.id == 'principiante');

      textIt =
          'Principiante evolve tramite Oculum Spento.\n\n'
          '${titleDetailIt(principiante)}\n\n'
          'Oculum Spento rimasto: $oculumSpento.';
      textEn =
          'Beginner evolves through Spent Oculum.\n\n'
          '${titleDetailEn(principiante)}\n\n'
          'Spent Oculum left: $oculumSpento.';
    });
  }

  String runTitleArtworkIt() {
    return '╔════════ Occhio della Run ════════╗\n'
        '        ◐      ◉      ◑\n'
        '    spine d’ombra • lanterne basse\n'
        '      piccoli pixel di cenere viva\n'
        '╚════ i Titoli guardano con te ════╝';
  }

  String runTitleArtworkEn() {
    return '╔════════ Run Eye ════════╗\n'
        '        ◐      ◉      ◑\n'
        '    shadow thorns • low lanterns\n'
        '      tiny pixels of living ash\n'
        '╚════ Titles watch with you ════╝';
  }

  void showTitleChoices() {
    setState(() {
      clearChoices(mode: 'unlocks');

      if (!runActive) {
        textIt =
            'I Titoli non appaiono fuori dalla run.\n\n'
            'L’occhio non presta nomi a chi non sta camminando nel dungeon.';
        textEn =
            'Titles do not appear outside the run.\n\n'
            'The eye does not lend names to those who are not walking inside the dungeon.';
        return;
      }

      final activeTitles = equippedTitles.toList();

      textIt =
          '${runTitleArtworkIt()}\n\n'
          'Titoli della run.\n\n'
          'Qui vedi solo i Titoli attivi in questa run.\n'
          'Non puoi cambiare build fuori dal cammino: ogni Titolo trovato resta una cicatrice temporanea.\n\n'
          'Attivi: ${activeTitles.map((t) => '${titleNameIt(t)} Lv.${titleLevel(t.id)}').join(', ')}';
      textEn =
          '${runTitleArtworkEn()}\n\n'
          'Run Titles.\n\n'
          'Here you only see Titles active in this run.\n'
          'You cannot change the build outside the path: each found Title remains a temporary scar.\n\n'
          'Active: ${activeTitles.map((t) => '${titleNameEn(t)} Lv.${titleLevel(t.id)}').join(', ')}';

      for (final title in activeTitles) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: '${titleNameIt(title)} Lv.${titleLevel(title.id)}',
            labelEn: '${titleNameEn(title)} Lv.${titleLevel(title.id)}',
            icon: title.id == 'principiante'
                ? Icons.visibility
                : title.strong
                ? Icons.workspace_premium
                : Icons.style,
            color: title.id == 'principiante'
                ? widget.tertiaryColor
                : title.strong
                ? Colors.amber
                : const Color(0xFFA78BFA),
            onPressed: () {
              setState(() {
                textIt = '${runTitleArtworkIt()}\n\n${titleDetailIt(title)}';
                textEn = '${runTitleArtworkEn()}\n\n${titleDetailEn(title)}';
              });
            },
          ),
        );
      }
    });
  }

  void toggleTitle(_TitleDef title) {
    setState(() {
      final wasEquipped = equippedTitleIds.contains(title.id);

      if (wasEquipped) {
        if (title.id == 'principiante') {
          textIt =
              'Principiante non può essere rimosso dalla prima impostazione.\n\n${titleDetailIt(title)}';
          textEn =
              'Beginner cannot be removed from the first setting.\n\n${titleDetailEn(title)}';
          return;
        }

        equippedTitleIds.remove(title.id);
        _savePermanentProgress();
        showTitleChoices();

        textIt = 'Titolo rimosso:\n\n${titleDetailIt(title)}\n\n$textIt';
        textEn = 'Title removed:\n\n${titleDetailEn(title)}\n\n$textEn';
        return;
      }

      if (equippedTitleIds.length >= titleSlotLimit) {
        textIt =
            'Slot Titolo pieni: $titleSlotLimit.\n\n'
            'Titolo selezionato:\n\n'
            '${titleDetailIt(title)}';
        textEn =
            'Title slots full: $titleSlotLimit.\n\n'
            'Selected Title:\n\n'
            '${titleDetailEn(title)}';
        return;
      }

      equippedTitleIds.add(title.id);
      _savePermanentProgress();
      showTitleChoices();

      textIt = 'Titolo impostato:\n\n${titleDetailIt(title)}\n\n$textIt';
      textEn = 'Title equipped:\n\n${titleDetailEn(title)}\n\n$textEn';
    });
  }

  _TitleDef unlockRandomTitle() {
    final pool =
        _allTitles.where((title) => (titleLevels[title.id] ?? 0) < 12).toList()
          ..shuffle(_random);

    final title = pool.isEmpty
        ? (_allTitles.toList()..shuffle(_random)).first
        : pool.first;

    unlockedTitleIds.add(title.id);
    final lvl = titleLevels[title.id] ?? 0;
    titleLevels[title.id] = min(12, max(1, lvl + 1)).toInt();
    _savePermanentProgress();
    return title;
  }

  void showAchievementChoices() {
    setState(() {
      clearChoices(mode: 'achievement');
      checkPassiveAchievements();

      final completed = completedAchievementIds.length;
      final total = _achievements.length;

      textIt =
          'Achievement di Oculum.\n\n'
          'Completati: $completed/$total.\n'
          'Molti sono davvero nascosti: restano ??? finché non li completi.\n'
          'Le ricompense vengono applicate subito e riparate automaticamente se mancavano.';
      textEn =
          'Oculum Achievements.\n\n'
          'Completed: $completed/$total.\n'
          'Many are truly hidden: they stay ??? until completed.\n'
          'Rewards are applied immediately and automatically repaired if missing.';

      final ordered = List<_AchievementDef>.from(_achievements)
        ..sort((a, b) {
          final aDone = completedAchievementIds.contains(a.id);
          final bDone = completedAchievementIds.contains(b.id);
          if (aDone != bDone) return aDone ? -1 : 1;
          final aHidden = a.hidden && !aDone;
          final bHidden = b.hidden && !bDone;
          if (aHidden != bHidden) return aHidden ? 1 : -1;
          return a.titleIt.compareTo(b.titleIt);
        });

      for (final achievement in ordered) {
        final done = completedAchievementIds.contains(achievement.id);
        final hidden = achievement.hidden && !done;
        eventChoices.add(
          _DungeonChoice(
            labelIt: hidden
                ? '???'
                : '${done ? '✓ ' : ''}${achievement.titleIt}',
            labelEn: hidden
                ? '???'
                : '${done ? '✓ ' : ''}${achievement.titleEn}',
            icon: done ? Icons.emoji_events : Icons.help_outline,
            color: done
                ? Colors.amber
                : hidden
                ? const Color(0xFF5B21B6)
                : const Color(0xFF8B5CF6),
            onPressed: () {
              setState(() {
                final nowDone = completedAchievementIds.contains(
                  achievement.id,
                );
                final nowHidden = achievement.hidden && !nowDone;
                final nowRewardApplied = achievementRewardAlreadyApplied(
                  achievement,
                );

                if (nowHidden) {
                  textIt =
                      '???\n\n'
                      'Achievement nascosto.\n'
                      'Non rivela nome, condizione o ricompensa finché non lo completi.';
                  textEn =
                      '???\n\n'
                      'Hidden achievement.\n'
                      'It does not reveal name, condition or reward until completed.';
                  return;
                }

                textIt =
                    '${achievement.titleIt}\n\n'
                    '${achievement.descIt}\n\n'
                    'Ricompensa: ${achievement.rewardIt}\n'
                    'Tipo: ${achievement.rewardType}\n'
                    'Stato: ${nowDone ? 'Completato' : 'Non completato'}\n'
                    'Ricompensa applicata: ${nowRewardApplied
                        ? 'Sì'
                        : nowDone
                        ? 'Da riparare'
                        : 'No'}';
                textEn =
                    '${achievement.titleEn}\n\n'
                    '${achievement.descEn}\n\n'
                    'Reward: ${achievement.rewardEn}\n'
                    'Type: ${achievement.rewardType}\n'
                    'Status: ${nowDone ? 'Completed' : 'Not completed'}\n'
                    'Reward applied: ${nowRewardApplied
                        ? 'Yes'
                        : nowDone
                        ? 'Needs repair'
                        : 'No'}';
              });
            },
          ),
        );
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Chiudi achievement',
          labelEn: 'Close achievements',
          icon: Icons.close,
          color: Colors.blueGrey,
          onPressed: () {
            setState(() {
              clearChoices();
              textIt = 'Pannello achievement chiuso.';
              textEn = 'Achievement panel closed.';
            });
          },
        ),
      );
    });
  }

  bool isSmallNpc(_GoodNpc npc) {
    const smallIds = {
      'kooba_glimmer_moralist',
      'slime_prince_page',
      'thousand_eyes_child',
      'minor_oculian_watcher',
      'apothecary_moth',
      'bone_cartographer',
      'little_sun_liturgist',
      'mela_seedling',
      'lucciola_fredda',
      'rana_di_sale',
      'rana_insalata',
      'gufus_leviante',
      'affogato_temporaneo',
      'affogato_temporaneo_2',
      'affogato_temporaneo_3',
      'affogato_temporaneo_4',
    };

    return smallIds.contains(npc.id) ||
        npc.nameIt.toLowerCase().contains('piccola') ||
        npc.nameIt.toLowerCase().contains('bambino') ||
        npc.nameIt.toLowerCase().contains('kooba') ||
        npc.nameIt.toLowerCase().contains('slime');
  }

  int rollSmallNpcActions(_GoodNpc npc) {
    final base = 3 + _random.nextInt(4); // 3-6 azioni.
    final floorBonus = currentFloor >= 6 ? 1 : 0;
    final posteaMemoryBonus =
        npc.id == 'gufus_leviante' && posteaGufusEventCompleted ? 1 : 0;
    return base + floorBonus + posteaMemoryBonus;
  }

  void prepareSmallNpcActions(_GoodNpc npc, {bool forceRefresh = false}) {
    if (!isSmallNpc(npc)) return;

    if (forceRefresh ||
        !smallNpcActions.containsKey(npc.id) ||
        (smallNpcActions[npc.id] ?? 0) <= 0) {
      smallNpcActions[npc.id] = rollSmallNpcActions(npc);
    }
  }

  int get activeTemporaryDrownedCount =>
      activeAllies.where((npc) => drownedNpcIds.contains(npc.id)).length;

  int get maxTemporaryDrowned =>
      activeRelic?.effectId == 'ahrya_extra_ally' ? 4 : 3;

  List<String> get drownedNpcIds => const [
    'affogato_temporaneo',
    'affogato_temporaneo_2',
    'affogato_temporaneo_3',
    'affogato_temporaneo_4',
  ];

  bool get hasDrownedNecromancy =>
      activeCostume?.id == 'drowned_city_robe' || drownedSummonTurns > 0;

  void summonDrownedAlliesFromLastFight() {
    if (!hasDrownedNecromancy || defeatedEnemyNamesIt.isEmpty) return;

    final wanted = maxTemporaryDrowned;
    final already = activeAllies
        .where((npc) => drownedNpcIds.contains(npc.id))
        .length;
    final freeByDrownedLimit = max(0, wanted - already).toInt();

    // Gli Affogati hanno slot propri: non devono essere bloccati dal party normale pieno.
    final amount = min(freeByDrownedLimit, defeatedEnemyNamesIt.length).toInt();

    if (amount <= 0) {
      addLog(
        t(
          'Necromanzia acquatica pronta, ma nessuno slot Affogato libero o nessun nemico caduto.',
          'Aquatic necromancy ready, but no Drowned slot is free or no enemy fell.',
        ),
      );
      return;
    }

    var summoned = 0;
    for (final id in drownedNpcIds.take(wanted)) {
      if (summoned >= amount) break;
      if (activeAllies.any((npc) => npc.id == id)) continue;

      final npc = _goodNpcs.firstWhere((n) => n.id == id);
      activeAllies.add(npc);
      smallNpcActions[id] = 3;
      summoned++;
    }

    if (summoned > 0) {
      drownedSummonTurns = max(drownedSummonTurns, 3).toInt();
      final maxLineIt = maxTemporaryDrowned == 4
          ? 'Il Romanzo tiene aperto un quarto ricordo.'
          : 'Senza Romanzo il limite resta 3 Affogati.';
      final maxLineEn = maxTemporaryDrowned == 4
          ? 'The Novel keeps a fourth memory open.'
          : 'Without the Novel the limit remains 3 Drowned.';

      textIt +=
          '\nNecromanzia acquatica: $summoned Affogati RESTANO nel party per 3 azioni ciascuno e possono prendere colpi al posto tuo. '
          '$maxLineIt Ora attivi: $activeTemporaryDrownedCount/$maxTemporaryDrowned.';
      textEn +=
          '\nAquatic necromancy: $summoned Drowned STAY in the party for 3 actions each and can take hits instead of you. '
          '$maxLineEn Active now: $activeTemporaryDrownedCount/$maxTemporaryDrowned.';

      addLog(
        t(
          'Affogati temporanei nel party: $activeTemporaryDrownedCount/$maxTemporaryDrowned.',
          'Temporary Drowned in party: $activeTemporaryDrownedCount/$maxTemporaryDrowned.',
        ),
      );
    }
  }

  List<_GoodNpc> activeSmallNpcs() {
    return activeAllies
        .where(isSmallNpc)
        .where((npc) => (smallNpcActions[npc.id] ?? 0) > 0)
        .toList();
  }

  String smallNpcLeaveLineIt(_GoodNpc npc) {
    switch (npc.id) {
      case 'mela_seedling':
        return 'Mela Verde Piccola si sistema una fogliolina e sussurra: “torno nel vaso, ma tu non morire male.”';
      case 'lucciola_fredda':
        return 'Lucciola Fredda si spegne piano: “la luce piccola basta solo finché qualcuno la guarda.”';
      case 'rana_di_sale':
        return 'Rana di Sale gracida: “sale sulle ferite, ma non sul cuore.” Poi salta via.';
      case 'rana_insalata':
        return 'Rana Insalata gonfia il petto verde: “la Resilienza è croccante.” Poi sparisce tra le foglie.';
      case 'gufus_leviante':
        return 'Gufus Leviante il Grande Eroe chiude il mantello nero: “il grande eroe continuerà altrove, plebe dell’occhio.”';
      case 'affogato_temporaneo':
      case 'affogato_temporaneo_2':
      case 'affogato_temporaneo_3':
      case 'affogato_temporaneo_4':
        return '${npc.nameIt} smette di ricordare il proprio nome e torna giù, dove l’acqua non fa domande.';
      case 'kooba_glimmer_moralist':
        return 'Kooba controlla che nessuno abbia rubato nulla e mormora: “solo ciò che è abbandonato.”';
      case 'slime_prince_page':
        return 'Il Paggetto Slime fa un inchino molle: “il Principe chiamerà, prima o poi.”';
      case 'thousand_eyes_child':
        return 'Il Bambino dai Mille Occhi asciuga troppe lacrime: “non tutte erano mie.”';
      case 'minor_oculian_watcher':
        return 'L’Oculiano Minore smette di guardarti: “per ora sei ancora leggibile.”';
      case 'apothecary_moth':
        return 'La Falena Speziale lascia una polvere amara: “non respirarla tutta insieme.”';
      case 'bone_cartographer':
        return 'Il Cartografo d’Ossa piega la mappa: “questa strada non voleva essere trovata.”';
      case 'little_sun_liturgist':
        return 'La Piccola Liturgista del Sole abbassa la candela: “anche il Sole si stanca.”';
      default:
        return '${npc.nameIt} se ne va piano, lasciando una traccia piccola nel dungeon.';
    }
  }

  String smallNpcLeaveLineEn(_GoodNpc npc) {
    switch (npc.id) {
      case 'mela_seedling':
        return 'Small Green Apple adjusts a little leaf and whispers: “I’m going back to the pot, but don’t die badly.”';
      case 'lucciola_fredda':
        return 'Cold Firefly dims softly: “small light lasts only while someone watches it.”';
      case 'rana_di_sale':
        return 'Salt Frog croaks: “salt on wounds, but not on the heart.” Then it hops away.';
      case 'rana_insalata':
        return 'Salad Frog puffs its green chest: “Resilience is crunchy.” Then it vanishes among leaves.';
      case 'gufus_leviante':
        return 'Gufus Leviante the Great Hero closes his black cloak: “the great hero shall continue elsewhere, eye-peasants.”';
      case 'affogato_temporaneo':
      case 'affogato_temporaneo_2':
      case 'affogato_temporaneo_3':
      case 'affogato_temporaneo_4':
        return '${npc.nameEn} stops remembering its own name and sinks back down, where water asks no questions.';
      case 'kooba_glimmer_moralist':
        return 'Kooba checks that nobody stole anything and mutters: “only what was abandoned.”';
      case 'slime_prince_page':
        return 'The Slime Page gives a soft bow: “the Prince will call, sooner or later.”';
      case 'thousand_eyes_child':
        return 'The Thousand-Eyed Child wipes too many tears: “not all of them were mine.”';
      case 'minor_oculian_watcher':
        return 'The Minor Oculian stops watching you: “for now, you are still readable.”';
      case 'apothecary_moth':
        return 'The Apothecary Moth leaves bitter powder behind: “do not breathe it all at once.”';
      case 'bone_cartographer':
        return 'The Bone Cartographer folds the map: “this road did not want to be found.”';
      case 'little_sun_liturgist':
        return 'The Little Sun Liturgist lowers her candle: “even the Sun gets tired.”';
      default:
        return '${npc.nameEn} leaves slowly, leaving a small trace in the dungeon.';
    }
  }

  void removeSmallNpcFromParty(
    _GoodNpc npc, {
    required String reasonIt,
    required String reasonEn,
  }) {
    activeAllies.removeWhere((ally) => ally.id == npc.id);
    smallNpcActions.remove(npc.id);

    final officialIt = !inCombat ? '\n${smallNpcLeaveLineIt(npc)}' : '';
    final officialEn = !inCombat ? '\n${smallNpcLeaveLineEn(npc)}' : '';

    if (!inCombat) {
      textIt += officialIt;
      textEn += officialEn;
    }

    addLog(
      t(
        '${npc.nameIt}: $reasonIt$officialIt',
        '${npc.nameEn}: $reasonEn$officialEn',
      ),
    );
  }

  void smallNpcSupportAction(_GoodNpc ally, List<_EnemyInstance> aliveEnemies) {
    final left = smallNpcActions[ally.id] ?? 0;
    if (left <= 0) return;

    final target = aliveEnemies.isEmpty
        ? null
        : aliveEnemies[_random.nextInt(aliveEnemies.length)];

    switch (ally.id) {
      case 'kooba_glimmer_moralist':
        sparklingGears += 1;
        gainPlayerShield(3 + currentFloor ~/ 2);
        if (target != null) {
          target.hp = max(0, target.hp - (2 + currentFloor ~/ 2)).toInt();
        }
        textIt +=
            '\nKooba combatte piano: +1 Ingranaggio, piccolo Scudo e un morso morale.';
        textEn +=
            '\nKooba fights softly: +1 Gear, small Shield and a moral bite.';
        break;

      case 'thousand_eyes_child':
        final shield = 5 + currentFloor;
        gainPlayerShield(shield);
        if (chance(18)) enemyWeak += 1;
        textIt += '\nBambino dai Mille Occhi piange: +$shield Scudo.';
        textEn += '\nThousand-Eyed Child cries: +$shield Shield.';
        break;

      case 'minor_oculian_watcher':
        if (chance(35)) gainOculumCharges(1);
        enemyWeak += 1;
        textIt +=
            '\nOculiano Minore osserva il nemico: +1 Debolezza e possibile Oculum.';
        textEn +=
            '\nMinor Oculian watches the enemy: +1 Weakness and possible Oculum.';
        break;

      case 'slime_prince_page':
        gainPlayerShield(6 + currentFloor ~/ 2);
        if (target != null) target.hp = max(0, target.hp - 2).toInt();
        textIt += '\nPaggetto Slime rimbalza: piccolo Scudo e piccola botta.';
        textEn += '\nSlime Page bounces: small Shield and small hit.';
        break;

      case 'apothecary_moth':
        final heal = 3 + currentFloor ~/ 2;
        playerHp = min(playerMaxHp, playerHp + heal);
        if (chance(12)) addQuickPotion('minor', amount: 1);
        textIt += '\nFalena Speziale sparge polvere: +$heal HP.';
        textEn += '\nApothecary Moth scatters powder: +$heal HP.';
        break;

      case 'bone_cartographer':
        runCritBonus += 1;
        if (chance(15)) nextRoomSafe = true;
        textIt +=
            '\nCartografo d’Ossa segna una linea utile: +1 critico temporaneo.';
        textEn +=
            '\nBone Cartographer marks a useful line: +1 temporary critical.';
        break;

      case 'little_sun_liturgist':
        runCritBonus += 2;
        if (target != null) {
          target.hp = max(0, target.hp - (1 + currentFloor ~/ 2)).toInt();
        }
        textIt +=
            '\nPiccola Liturgista del Sole sussurra una briciola di luce.';
        textEn += '\nLittle Sun Liturgist whispers a crumb of light.';
        break;

      case 'mela_seedling':
        final heal = 3 + currentFloor ~/ 2;
        playerHp = min(playerMaxHp, playerHp + heal);
        if (target != null && chance(18)) {
          target.hp = max(0, target.hp - 1).toInt();
        }
        textIt += '\nMela Verde Piccola ti ricuce: +$heal HP.';
        textEn += '\nSmall Green Apple stitches you: +$heal HP.';
        break;

      case 'lucciola_fredda':
        runCritBonus += 1;
        if (target != null) {
          target.hp = max(0, target.hp - 1).toInt();
        }
        if (chance(12)) nextEnemyWeakened = true;
        textIt += '\nLucciola Fredda lampeggia: +1 critico e luce gelida.';
        textEn += '\nCold Firefly blinks: +1 critical and cold light.';
        break;

      case 'rana_di_sale':
        final shield = 4 + currentFloor ~/ 2;
        gainPlayerShield(shield);
        if (chance(10)) enemyWeak += 1;
        textIt += '\nRana di Sale gonfia la gola: +$shield Scudo.';
        textEn += '\nSalt Frog swells its throat: +$shield Shield.';
        break;

      case 'rana_insalata':
        final resGain = 1;
        dungeonResilienza += resGain;
        final heal = 4 + currentFloor;
        playerHp = min(playerMaxHp, playerHp + heal);
        textIt +=
            '\nRana Insalata mastica destino: +$resGain Resilienza e +$heal HP.';
        textEn +=
            '\nSalad Frog chews fate: +$resGain Resilience and +$heal HP.';
        break;

      case 'affogato_temporaneo':
      case 'affogato_temporaneo_2':
      case 'affogato_temporaneo_3':
      case 'affogato_temporaneo_4':
        if (target != null) {
          final damage = 6 + currentFloor + totalOculum ~/ 2;
          target.hp = max(0, target.hp - damage).toInt();
          enemyWeak += 1;
          textIt +=
              '\n${ally.nameIt} è ancora con te: trascina acqua morta, $damage danni e +1 Debolezza. Azioni rimaste dopo questa: ${max(0, (smallNpcActions[ally.id] ?? 1) - 1)}.';
          textEn +=
              '\n${ally.nameEn} is still with you: it drags dead water, $damage damage and +1 Weakness. Actions left after this: ${max(0, (smallNpcActions[ally.id] ?? 1) - 1)}.';
        }
        break;

      case 'gufus_leviante':
        // Sputo Velenoso I: danno velenoso pesante, circa 1/4 della vita del bersaglio.
        if (target != null) {
          final poisonDamage = max(2, target.maxHp ~/ 4);
          target.hp = max(0, target.hp - poisonDamage).toInt();
          enemyBleed += 1;
          textIt +=
              '\nGufus Leviante sputa veleno: $poisonDamage danni velenosi (1/4).';
          textEn +=
              '\nGufus Leviante spits poison: $poisonDamage poison damage (1/4).';
        }

        // Velocità della Civetta I: piccola reazione extra/ombra.
        dodgeCharges += 1;
        reactionAvailable = true;
        runCritBonus += 1;

        // Trasformazione in Bestia I: rara, istintiva, non completamente controllata.
        if (!hasRunFlag('gufus_beast_transformation_used') && chance(10)) {
          runBoons.add('gufus_beast_transformation_used');
          dungeonResilienza += 10;
          dungeonVolonta += 10;
          dungeonMateria += 10;
          dungeonOculum += 10;
          runDamageBonus += 20;
          textIt +=
              '\nGufus perde il mantello: Trasformazione in Bestia. La dolce civetta bianca col mantello nero, il cappuccio e il piccolo coltellino scompare e davanti a te si apre un’enorme civetta in decadimento, con acido che cola dalla bocca e occhi bianchi vitrei. +10 a tutte le stats e +20 danni al prossimo impeto.';
          textEn +=
              '\nGufus loses the cloak: Beast Transformation. The gentle white knee-high owl with the black hooded cloak and the small knife disappears, and before you opens a huge decaying owl, with acid dripping from its beak and milky white eyes. +10 to every stat and +20 damage for the next surge.';
        } else {
          textIt +=
              '\nGufus Leviante apre il mantello nero: +1 reazione e +1 critico.';
          textEn +=
              '\nGufus Leviante opens the black cloak: +1 reaction and +1 critical.';
        }
        break;

      default:
        gainPlayerShield(3);
        if (target != null) {
          target.hp = max(0, target.hp - 2).toInt();
        }
        textIt += '\n${ally.nameIt} ti aiuta con un buff minuscolo.';
        textEn += '\n${ally.nameEn} helps with a tiny buff.';
        break;
    }

    smallNpcActions[ally.id] = left - 1;

    if ((smallNpcActions[ally.id] ?? 0) <= 0) {
      if (inCombat && chance(3)) {
        final extra = 2 + _random.nextInt(3);
        smallNpcActions[ally.id] = extra;
        textIt += '\n${ally.nameIt} trema, ma resta ancora per $extra azioni.';
        textEn +=
            '\n${ally.nameEn} trembles, but stays for $extra more actions.';
      } else {
        removeSmallNpcFromParty(
          ally,
          reasonIt: 'ha finito le azioni e se ne va.',
          reasonEn: 'has spent all actions and leaves.',
        );
      }
    }
  }

  bool tryEnemyKillsSmallNpc(
    _EnemyInstance attacker,
    List<String> reportIt,
    List<String> reportEn,
  ) {
    final small = activeSmallNpcs();
    if (small.isEmpty) return false;
    if (!chance(9)) return false;

    final victim = small[_random.nextInt(small.length)];
    final leftBeforeDeath = smallNpcActions[victim.id] ?? 0;

    removeSmallNpcFromParty(
      victim,
      reasonIt:
          'si mette davanti a te e prende l’attacco al posto tuo. Muore proteggendoti.',
      reasonEn:
          'steps in front of you and takes the attack instead of you. They die protecting you.',
    );

    reportIt.add(
      '${attacker.nameIt} perde l’azione: ${victim.nameIt} prende il colpo al posto tuo e muore. '
      'Azioni rimaste prima del colpo: $leftBeforeDeath.',
    );
    reportEn.add(
      '${attacker.nameEn} loses its action: ${victim.nameEn} takes the hit instead of you and dies. '
      'Actions left before the hit: $leftBeforeDeath.',
    );

    return true;
  }

  bool addAllyToParty(
    _GoodNpc npc, {
    bool replaceIfFull = false,
    bool save = true,
  }) {
    if (npc.id == 'valley_child_of_mother_nature' && valleySacrificedInPostea) {
      return false;
    }

    if (activeAllies.any((ally) => ally.id == npc.id)) {
      return true;
    }

    if (activeRelic?.effectId == 'skeleton_hands' &&
        npc.id == 'giant_skull_tavernkeeper') {
      return false;
    }

    if (activeAllies.length >= maxActiveAllies) {
      if (!replaceIfFull) return false;
      final removed = activeAllies.removeAt(0);
      if (removed.id == 'postea_elite_guard') {
        clearPosteaEliteGuardState();
      }
    }

    activeAllies.add(npc);
    prepareSmallNpcActions(npc, forceRefresh: true);
    if (npc.id == 'postea_elite_guard') {
      activatePosteaEliteGuard(refill: true);
    }
    alliesRecruitedTotal++;
    if (runActive && npc.id == 'gufus_leviante') {
      gufusUsedThisRun = true;
    }

    if (activeAllies.length >= 2) {
      completeAchievement('party_two');
    }

    if (save) {
      _savePermanentProgress();
    }

    return true;
  }

  void autoBringNpcRewardIfPossible(String npcId) {
    if (!runActive || gameOver) return;

    final matches = _goodNpcs.where((npc) => npc.id == npcId).toList();
    if (matches.isEmpty) return;

    final npc = matches.first;
    final joined = addAllyToParty(npc, save: false);

    if (joined) {
      addLog(
        t(
          '${npc.nameIt} entra davvero nel party.',
          '${npc.nameEn} truly joins the party.',
        ),
      );
    } else {
      addLog(
        t(
          '${npc.nameIt} è sbloccato, ma il party è pieno.',
          '${npc.nameEn} is unlocked, but the party is full.',
        ),
      );
    }
  }

  void rebuildAllyChoicesContent() {
    clearChoices(mode: 'allies');

    final unlocked = _goodNpcs
        .where((npc) => unlockedNpcIds.contains(npc.id))
        .where(
          (npc) =>
              !(npc.id == 'valley_child_of_mother_nature' &&
                  valleySacrificedInPostea),
        )
        .toList();

    if (runActive) {
      textIt =
          'Party della run.\n\n'
          'Qui appaiono solo gli NPC vivi nella run: i due scelti prima di partire e quelli trovati nel dungeon.\n'
          'Se un NPC muore, finisce le azioni o se ne va, sparisce da questa tendina.\n\n'
          'Party attuale: ${activeAllies.isEmpty ? 'nessuno' : activeAllies.map((a) => a.nameIt).join(', ')}';
      textEn =
          'Run party.\n\n'
          'Only NPCs alive in this run appear here: the two chosen before starting and those found in the dungeon.\n'
          'If an NPC dies, spends all actions or leaves, it disappears from this menu.\n\n'
          'Current party: ${activeAllies.isEmpty ? 'none' : activeAllies.map((a) => a.nameEn).join(', ')}';

      for (final npc in activeAllies) {
        final actionsIt = isPosteaEliteGuard(npc)
            ? '\n\nVita guardia: $posteaEliteGuardHp/$posteaEliteGuardMaxHp. '
                  'Scudo: $posteaEliteGuardShield. '
                  'Scudo Critico: ${posteaEliteGuardCriticalShieldActive ? 'attivo' : 'rotto'}. '
                  'Set: Fucile Automatico, Granate e Armatura Élite.'
            : isSmallNpc(npc)
            ? '\n\nAzioni rimaste: ${smallNpcActions[npc.id] ?? 0}.'
            : '';
        final actionsEn = isPosteaEliteGuard(npc)
            ? '\n\nGuard HP: $posteaEliteGuardHp/$posteaEliteGuardMaxHp. '
                  'Shield: $posteaEliteGuardShield. '
                  'Critical Shield: ${posteaEliteGuardCriticalShieldActive ? 'active' : 'broken'}. '
                  'Set: Automatic Rifle, Grenades and Elite Armor.'
            : isSmallNpc(npc)
            ? '\n\nActions left: ${smallNpcActions[npc.id] ?? 0}.'
            : '';
        eventChoices.add(
          _DungeonChoice(
            labelIt: npc.nameIt,
            labelEn: npc.nameEn,
            icon: Icons.person,
            color: elementColor(npc.elementId),
            onPressed: () {
              setState(() {
                textIt = '${npc.nameIt}\n\n${npc.descIt}$actionsIt';
                textEn = '${npc.nameEn}\n\n${npc.descEn}$actionsEn';
              });
            },
          ),
        );
      }

      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Chiudi party',
          labelEn: 'Close party',
          icon: Icons.close,
          color: Colors.blueGrey,
          onPressed: () {
            setState(() {
              clearChoices();
              textIt = 'Pannello party chiuso.';
              textEn = 'Party panel closed.';
            });
          },
        ),
      );
      return;
    }

    textIt =
        'Selezione NPC per la prossima run.\n\n'
        'Puoi scegliere massimo $maxActiveAllies NPC buoni prima di partire.\n'
        'Durante la run la tendina mostrerà solo questi due più gli NPC trovati nel dungeon.\n'
        'Gli NPC piccoli possono anche prendere un colpo al posto tuo e morire proteggendoti.\n\n'
        'Selezionati: ${selectedAllyIds.isEmpty ? 'nessuno' : _goodNpcs.where((a) => selectedAllyIds.contains(a.id)).map((a) => a.nameIt).join(', ')}';
    textEn =
        'NPC selection for the next run.\n\n'
        'You can choose up to $maxActiveAllies good NPCs before starting.\n'
        'During the run this menu will show only those two plus NPCs found in the dungeon.\n'
        'Small NPCs may also take a hit instead of you and die protecting you.\n\n'
        'Selected: ${selectedAllyIds.isEmpty ? 'none' : _goodNpcs.where((a) => selectedAllyIds.contains(a.id)).map((a) => a.nameEn).join(', ')}';

    if (unlocked.isEmpty) {
      textIt += '\n\nNessun NPC buono sbloccato. Completa achievement.';
      textEn += '\n\nNo good NPC unlocked. Complete achievements.';
      return;
    }

    for (final npc in unlocked) {
      final active = selectedAllyIds.contains(npc.id);

      eventChoices.add(
        _DungeonChoice(
          labelIt: '${active ? 'Togli' : 'Scegli'}: ${npc.nameIt}',
          labelEn: '${active ? 'Remove' : 'Choose'}: ${npc.nameEn}',
          icon: active ? Icons.person_remove : Icons.person_add,
          color: elementColor(npc.elementId),
          onPressed: () => toggleAlly(npc),
        ),
      );
    }

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Chiudi alleati',
        labelEn: 'Close allies',
        icon: Icons.close,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt = 'Pannello alleati chiuso.';
            textEn = 'Allies panel closed.';
          });
        },
      ),
    );
  }

  void showAllyChoices() {
    setState(() {
      rebuildAllyChoicesContent();
    });
  }

  void toggleAlly(_GoodNpc npc) {
    setState(() {
      if (npc.id == 'valley_child_of_mother_nature' &&
          valleySacrificedInPostea) {
        rebuildAllyChoicesContent();
        textIt =
            'Valley non può più essere scelto: si e sacrificato a Postea.\n\n$textIt';
        textEn =
            'Valley can no longer be chosen: it was sacrificed in Postea.\n\n$textEn';
        return;
      }

      if (runActive) {
        final already = activeAllies.any((ally) => ally.id == npc.id);
        if (already) {
          activeAllies.removeWhere((ally) => ally.id == npc.id);
          smallNpcActions.remove(npc.id);
          if (npc.id == 'postea_elite_guard') {
            clearPosteaEliteGuardState();
          }
          textIt = '${npc.nameIt} rimosso dal party della run.';
          textEn = '${npc.nameEn} removed from run party.';
        } else {
          if (activeAllies.length >= maxActiveAllies) {
            textIt =
                'Party run pieno ($maxActiveAllies). Rimuovi prima un alleato.';
            textEn =
                'Run party is full ($maxActiveAllies). Remove an ally first.';
          } else {
            addAllyToParty(npc, save: false);
            textIt = '${npc.nameIt} aggiunto al party della run.';
            textEn = '${npc.nameEn} added to run party.';
          }
        }
        saveRunCheckpoint(
          reasonIt: 'Party run aggiornato manualmente.',
          reasonEn: 'Run party manually updated.',
        );
        rebuildAllyChoicesContent();
        return;
      }

      if (selectedAllyIds.contains(npc.id)) {
        selectedAllyIds.remove(npc.id);
        activeAllies.removeWhere((ally) => ally.id == npc.id);
        if (npc.id == 'postea_elite_guard') {
          clearPosteaEliteGuardState();
        }
        _savePermanentProgress();

        final msgIt = '${npc.nameIt} tolto dalla prossima run.';
        final msgEn = '${npc.nameEn} removed from the next run.';

        rebuildAllyChoicesContent();
        textIt = '$msgIt\n\n$textIt';
        textEn = '$msgEn\n\n$textEn';
        return;
      }

      if (activeRelic?.effectId == 'skeleton_hands' &&
          npc.id == 'giant_skull_tavernkeeper') {
        final msgIt =
            'Mani del Teschio impediscono di riequipaggiare il Taverniere fino alla prossima run.';
        final msgEn =
            'Skull Hands prevent re-equipping the Tavernkeeper until next run.';
        rebuildAllyChoicesContent();
        textIt = '$msgIt\n\n$textIt';
        textEn = '$msgEn\n\n$textEn';
        return;
      }

      if (selectedAllyIds.length >= maxActiveAllies) {
        final msgIt =
            'Puoi scegliere massimo $maxActiveAllies NPC buoni per la prossima run.';
        final msgEn =
            'You can choose up to $maxActiveAllies good NPCs for the next run.';

        rebuildAllyChoicesContent();
        textIt = '$msgIt\n\n$textIt';
        textEn = '$msgEn\n\n$textEn';
        return;
      }

      selectedAllyIds.add(npc.id);
      activeAllies
        ..clear()
        ..addAll(_goodNpcs.where((ally) => selectedAllyIds.contains(ally.id)));
      _savePermanentProgress();

      if (selectedAllyIds.length > maxActiveAllies) {
        rebuildAllyChoicesContent();
        textIt =
            'Non riesci a portare ${npc.nameIt}. Il party è pieno o una reliquia lo impedisce.\n\n$textIt';
        textEn =
            'You cannot bring ${npc.nameEn}. The party is full or a relic prevents it.\n\n$textEn';
        return;
      }

      final specialIt = npc.id == 'giant_skull_tavernkeeper'
          ? '\n\nQuando tornerai nella Taverna del Teschio Enorme, si metterà dietro il bancone: pasto gratis, sconti e nessuna possibilità di rifiutare la taverna.'
          : '';
      final specialEn = npc.id == 'giant_skull_tavernkeeper'
          ? '\n\nWhen you return to the Giant Skull Tavern, it will stand behind the counter: free meal, discounts and no chance to refuse the tavern.'
          : '';

      final msgIt =
          '${npc.nameIt} scelto per la prossima run.\n\n${npc.descIt}$specialIt';
      final msgEn =
          '${npc.nameEn} chosen for the next run.\n\n${npc.descEn}$specialEn';

      rebuildAllyChoicesContent();
      textIt = '$msgIt\n\n$textIt';
      textEn = '$msgEn\n\n$textEn';
    });
  }

  void syncPrimaryEnemyFromParty() {
    final alive = enemyParty.where((enemy) => enemy.hp > 0).toList();

    if (alive.isEmpty) {
      enemyHp = 0;
      enemyMaxHp = 0;
      enemyAttack = 0;
      enemyDefense = 0;
      enemyNameIt = '';
      enemyNameEn = '';
      enemyElementId = 'neutral';
      enemyIsBoss = false;
      enemyIsElite = false;
      return;
    }

    final first = alive.first;
    enemyHp = first.hp;
    enemyMaxHp = first.maxHp;
    enemyAttack = first.attack;
    enemyDefense = first.defense;
    enemyNameIt = first.nameIt;
    enemyNameEn = first.nameEn;
    enemyElementId = first.elementId;
    enemyIsBoss = first.boss;
    enemyIsElite = first.elite;
  }

  _EnemyInstance? firstAliveEnemy() {
    for (final enemy in enemyParty) {
      if (enemy.hp > 0) return enemy;
    }
    return null;
  }

  String enemyPartySummary() {
    if (enemyParty.isEmpty) return '—';

    return enemyParty
        .where((enemy) => enemy.hp > 0)
        .map(
          (enemy) =>
              '${widget.linguaInglese ? enemy.nameEn : enemy.nameIt} ${enemy.hp}/${enemy.maxHp}',
        )
        .join(' • ');
  }

  void alliesAct() {
    if (!inCombat || enemyParty.where((enemy) => enemy.hp > 0).isEmpty) return;
    if (activeAllies.isEmpty && !valleyInFight) return;

    var aliveEnemies = enemyParty.where((enemy) => enemy.hp > 0).toList();

    if (pawnHp > 0 && aliveEnemies.isNotEmpty) {
      pawnShield += 10;
      final target = aliveEnemies[_random.nextInt(aliveEnemies.length)];
      final damage = 8 + pawnVolonta ~/ 2 + pawnMateria ~/ 3 + currentFloor;
      target.hp = max(0, target.hp - damage).toInt();
      textIt += '\nPawn colpisce ${target.nameIt}: $damage danni.';
      textEn += '\nPawn hits ${target.nameEn}: $damage damage.';
      defeatDeadEnemiesFromParty();
      aliveEnemies = enemyParty.where((enemy) => enemy.hp > 0).toList();
    }

    if (cipoSerpentHp > 0 && aliveEnemies.isNotEmpty) {
      final target = aliveEnemies[_random.nextInt(aliveEnemies.length)];
      final damage = max(
        5,
        totalDamage + 5 + currentFloor - target.defense ~/ 4,
      );
      target.hp = max(0, target.hp - damage).toInt();
      enemyWeak += 1;
      textIt +=
          '\nIl serpente di Cipo morde ${target.nameIt}: $damage danni e fragilità.';
      textEn +=
          '\nCipo serpent bites ${target.nameEn}: $damage damage and fragility.';
      defeatDeadEnemiesFromParty();
      aliveEnemies = enemyParty.where((enemy) => enemy.hp > 0).toList();
    }

    for (final ally in List<_GoodNpc>.from(activeAllies)) {
      aliveEnemies = enemyParty.where((enemy) => enemy.hp > 0).toList();
      if (aliveEnemies.isEmpty) break;
      if (!activeAllies.any((npc) => npc.id == ally.id)) continue;
      if (ally.id == 'valley_child_of_mother_nature' && valleyInFight) {
        continue;
      }

      if (isSmallNpc(ally)) {
        smallNpcSupportAction(ally, aliveEnemies);
        continue;
      }

      switch (ally.role) {
        case 'healer':
          final heal = 4 + currentFloor + totalOculum ~/ 2;
          playerHp = min(playerMaxHp, playerHp + heal);
          textIt += '\n${ally.nameIt} cura $heal HP.';
          textEn += '\n${ally.nameEn} heals $heal HP.';
          break;

        case 'guard':
          final shield = 6 + currentFloor + totalDefense ~/ 8;
          gainPlayerShield(shield);
          textIt += '\n${ally.nameIt} protegge il party: +$shield Scudo.';
          textEn += '\n${ally.nameEn} guards the party: +$shield Shield.';
          break;

        case 'buffer':
          runCritBonus += 1;
          runDefenseBonus += currentFloor % 2 == 0 ? 1 : 0;
          textIt += '\n${ally.nameIt} intona un buff sottovoce.';
          textEn += '\n${ally.nameEn} whispers a buff.';
          break;

        case 'occult':
          if (chance(35)) {
            gainOculumCharges(1);
            textIt += '\n${ally.nameIt} ricarica 1 Oculum.';
            textEn += '\n${ally.nameEn} restores 1 Oculum.';
          } else {
            dungeonOculum += 1;
            textIt += '\n${ally.nameIt} aumenta Oculum della run.';
            textEn += '\n${ally.nameEn} increases run Oculum.';
          }
          break;

        case 'postea_elite_guard':
          if (posteaEliteGuardHp <= 0) {
            activeAllies.removeWhere((npc) => npc.id == ally.id);
            clearPosteaEliteGuardState();
            break;
          }

          posteaEliteGuardShield += 6 + currentFloor;
          final living = enemyParty.where((enemy) => enemy.hp > 0).toList();
          final useGrenade = living.length > 1 && chance(34);

          if (useGrenade) {
            final base = max(10, posteaEliteGuardAttack + totalVc ~/ 4);
            var totalHit = 0;
            for (final target in living) {
              final damage = max(1, base - target.defense ~/ 4);
              target.hp = max(0, target.hp - damage).toInt();
              totalHit += damage;
            }
            textIt +=
                '\n${ally.nameIt} usa Granate di Postea: danno VC ad area senza spendere Oculum. Totale $totalHit danni.';
            textEn +=
                '\n${ally.nameEn} uses Postea Grenades: VC area damage without spending Oculum. $totalHit total damage.';
          } else {
            final target = living[_random.nextInt(living.length)];
            final shots = chance(30) ? 3 : 2;
            var totalHit = 0;
            for (var shot = 0; shot < shots; shot++) {
              final damage = max(
                1,
                posteaEliteGuardAttack + 8 - target.defense ~/ 5,
              );
              target.hp = max(0, target.hp - damage).toInt();
              totalHit += damage;
              if (target.hp <= 0) break;
            }
            textIt +=
                '\n${ally.nameIt} spara col Fucile Automatico di Postea: $shots raffiche su ${target.nameIt}, $totalHit danni.';
            textEn +=
                '\n${ally.nameEn} fires the Postea Automatic Rifle: $shots bursts at ${target.nameEn}, $totalHit damage.';
          }

          if (chance(22)) {
            posteaEliteGuardShield += 14;
            gainPlayerShield(8);
            textIt +=
                '\nArmatura Élite Postea: protocolli difensivi, +14 Scudo guardia e +8 Scudo party.';
            textEn +=
                '\nPostea Elite Armor: defensive protocols, +14 guard Shield and +8 party Shield.';
          }
          break;

        case 'postea_bloom':
          final target = aliveEnemies[_random.nextInt(aliveEnemies.length)];
          final damage = max(
            8,
            totalDamage + totalVc ~/ 2 + currentFloor * 4 - target.defense ~/ 5,
          );
          target.hp = max(0, target.hp - damage).toInt();
          enemyWeak += 2;
          gainPlayerShield(8 + currentFloor);
          textIt +=
              '\n${ally.nameIt} sboccia contro ${target.nameIt}: $damage danni, +2 Fragilità e scudo vegetale.';
          textEn +=
              '\n${ally.nameEn} blooms against ${target.nameEn}: $damage damage, +2 Fragility and plant shield.';
          break;

        default:
          final target = aliveEnemies[_random.nextInt(aliveEnemies.length)];
          final damage = max(
            1,
            5 + currentFloor + totalOculum ~/ 2 - target.defense ~/ 4,
          );
          target.hp = max(0, target.hp - damage).toInt();
          textIt +=
              '\n${ally.nameIt} colpisce ${target.nameIt}: $damage danni.';
          textEn += '\n${ally.nameEn} hits ${target.nameEn}: $damage damage.';
          break;
      }
    }

    valleySupportAction();
    defeatDeadEnemiesFromParty();
    syncPrimaryEnemyFromParty();
  }

  void valleySupportAction() {
    if (!valleyInFight || valleyTrainingActive) return;
    final aliveEnemies = enemyParty.where((enemy) => enemy.hp > 0).toList();
    if (aliveEnemies.isEmpty) return;

    valleyParticipatedInFight = true;
    valleyTurnsLeft = max(0, valleyTurnsLeft - 1).toInt();
    final baseDamage = max(
      8,
      valleyAttack +
          currentFloor * 2 +
          totalOculum -
          aliveEnemies.first.defense ~/ 4,
    ).toInt();

    textIt +=
        '\nValley concentra sfere trasparenti di natura e le scaglia contro i nemici.';
    textEn +=
        '\nValley concentrates transparent nature spheres and throws them at the enemies.';

    if (chance(30)) {
      textIt += '\nLe sfere di Valley si dividono in quattro raggi.';
      textEn += '\nValley spheres split into four rays.';
      for (var i = 0; i < 4; i++) {
        final targets = enemyParty.where((enemy) => enemy.hp > 0).toList();
        if (targets.isEmpty) break;
        final target = i < targets.length
            ? targets[i]
            : targets[_random.nextInt(targets.length)];
        final damage = max(
          1,
          (baseDamage * 0.62).round() - target.defense ~/ 5,
        );
        target.hp = max(0, target.hp - damage).toInt();
        textIt += '\nUn raggio cerca ${target.nameIt}: $damage danni.';
        textEn += '\nA ray seeks ${target.nameEn}: $damage damage.';
      }
    } else {
      final target = aliveEnemies[_random.nextInt(aliveEnemies.length)];
      final damage = max(1, baseDamage - target.defense ~/ 4);
      target.hp = max(0, target.hp - damage).toInt();
      textIt +=
          '\nValley scaglia una sfera concentrata di natura su ${target.nameIt}: $damage danni.';
      textEn +=
          '\nValley throws a compact nature sphere at ${target.nameEn}: $damage damage.';
    }

    if (valleyTurnsLeft <= 0 && valleyHp > 0) {
      textIt += '\nValley si dissolve tra sfere compatte di natura.';
      textEn += '\nValley dissolves among compact nature spheres.';
      valleyHp = 0;
    }
  }

  void defeatDeadEnemiesFromParty() {
    final dead = enemyParty.where((enemy) => enemy.hp <= 0).toList();
    if (dead.isEmpty) return;

    for (final enemy in dead) {
      registerSkinKill(enemy);
      defeatedEnemyNamesIt.add(enemy.nameIt);
      defeatedEnemyNamesEn.add(enemy.nameEn);
      final enemyPower = enemy.originalPower > 0
          ? enemy.originalPower
          : enemyPowerScoreFromStats(enemy.maxHp, enemy.attack, enemy.defense);
      defeatedEnemyPowerTotal += enemyPower;
      defeatedEnemyExpTotal += dungeonExpForEnemy(enemy);
      if (enemy.boss) defeatedBossCount++;
      if (enemy.elite) defeatedEliteCount++;
    }

    enemyParty.removeWhere((enemy) => enemy.hp <= 0);
  }

  void attackAllEnemies({required bool useVc}) {
    if (!canUseCombatInput || enemyParty.isEmpty) return;
    final freePosteaGrenades = useVc && posteaGrenadesEquipped;

    if (useVc && !canUseAoeVc()) {
      showLockedTechniqueMessage('AoE VC', 'VC AoE');
      return;
    }

    if (!useVc && !canUseAoeCm()) {
      showLockedTechniqueMessage('AoE CM', 'CM AoE');
      return;
    }

    if (!freePosteaGrenades && oculumCharges < 1) {
      showLockedTechniqueMessage(
        useVc
            ? 'AoE VC: serve 1 carica Oculum'
            : 'AoE CM: serve 1 carica Oculum',
        useVc
            ? 'VC AoE: needs 1 Oculum charge'
            : 'CM AoE: needs 1 Oculum charge',
      );
      return;
    }

    setState(() {
      clearChoices();

      if (!freePosteaGrenades) {
        oculumCharges -= 1;
      }
      aoeCasts++;
      final stat = useVc ? totalVc : totalCm;
      final baseDamage = max(
        1,
        ((totalDamage + stat ~/ 2 + elementalDamageBonus()) * 0.62).round(),
      );

      for (final enemy in enemyParty.where((enemy) => enemy.hp > 0)) {
        final attackType = useVc ? 'AoE VC' : 'AoE CM';
        final rawDamage = max(1, baseDamage - enemy.defense ~/ 3);
        final damage = damageAfterEnemyAdaptation(enemy, attackType, rawDamage);
        enemy.hp = max(0, enemy.hp - damage).toInt();
        applyBossAdaptation(enemy, attackType);

        if (!useVc) {
          enemy.attack = max(1, enemy.attack - 1).toInt();
        }
      }

      if (!useVc) {
        enemyWeak += 1 + totalCm ~/ 12;
      } else {
        combo += 1;
      }

      applyElementalComboBonus();

      textIt =
          '${freePosteaGrenades ? 'Granate di Postea' : 'Attacco ad area ${useVc ? 'VC' : 'CM'}'}.\n\n'
          'L’Oculum disegna un cerchio sporco sotto tutti i nemici.\n'
          'Danno base: $baseDamage.'
          '${freePosteaGrenades ? '\nNessuna carica Oculum spesa.' : ''}';
      textEn =
          '${freePosteaGrenades ? 'Postea Grenades' : '${useVc ? 'VC' : 'CM'} area attack'}.\n\n'
          'Oculum draws a dirty circle under every enemy.\n'
          'Base damage: $baseDamage.'
          '${freePosteaGrenades ? '\nNo Oculum charge spent.' : ''}';

      defeatDeadEnemiesFromParty();

      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }

      syncPrimaryEnemyFromParty();
      alliesAct();

      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }

      checkPassiveAchievements();
      enemyTurn();
    });
  }

  void showCorruptionCoreEvent({required bool purple}) {
    clearChoices(mode: 'event');

    final coreColorIt = purple ? 'viola' : 'rosso';
    final coreColorEn = purple ? 'purple' : 'red';

    textIt +=
        '\n\nCore di corruzione $coreColorIt.\n'
        'Dentro pulsa una reliquia. Puoi romperlo, prenderlo con te o andare via.';
    textEn +=
        '\n\n$coreColorEn corruption core.\n'
        'A relic pulses inside. You can break it, take it with you or leave.';

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Rompi il core di corruzione',
        labelEn: 'Break the corruption core',
        icon: Icons.dangerous,
        color: purple ? const Color(0xFFA78BFA) : Colors.redAccent,
        onPressed: () => breakCorruptionCore(purple: purple),
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Prendilo con te',
        labelEn: 'Take it with you',
        icon: Icons.inventory,
        color: const Color(0xFFFFD36A),
        onPressed: () => takeCorruptionCore(purple: purple),
      ),
    );

    eventChoices.add(
      _DungeonChoice(
        labelIt: 'Vai via',
        labelEn: 'Go away',
        icon: Icons.exit_to_app,
        color: Colors.blueGrey,
        onPressed: () {
          setState(() {
            clearChoices();
            textIt += '\n\nTi allontani dal core.';
            textEn += '\n\nYou walk away from the core.';
          });
        },
      ),
    );
  }

  void breakCorruptionCore({required bool purple}) {
    setState(() {
      clearChoices();

      if (purple || hasBaghestEye) {
        final relic = unlockRandomRelic();
        final money = purple ? 28 + currentFloor * 3 : 12 + currentFloor;
        final dust = purple ? 5 + currentFloor ~/ 2 : 2 + currentFloor ~/ 3;
        obserInRun += money;
        ascensionDustInRun += dust;
        textIt =
            'Core ${purple ? 'viola' : 'rosso'} spezzato senza infezione.\n+${relic?.nameIt ?? 'Reliquia'}\n+$money Obser\n+$dust Dust.';
        textEn =
            '${purple ? 'Purple' : 'Red'} core broken without infection.\n+${relic?.nameEn ?? 'Relic'}\n+$money Obser\n+$dust Dust.';
        return;
      }

      final roll = _random.nextInt(100) + 1;
      if (roll <= 6) {
        activeAllies.clear();
        clearPosteaEliteGuardState();
        _savePermanentProgress();
        textIt =
            'La corruzione ti prende. Uccidi i tuoi compagni. Non saranno trovabili fino alla prossima run.';
        textEn =
            'Corruption takes you. You kill your companions. They will not be findable until next run.';
        return;
      }

      if (roll <= 9) {
        playerHp = 0;
        textIt =
            'La corruzione ti prende. I tuoi compagni ti uccidono prima che tu diventi altro.';
        textEn =
            'Corruption takes you. Your companions kill you before you become something else.';
        if (!tryConsumeRebirthBlessing()) finishRun(victorious: false);
        return;
      }

      final relic = unlockRandomRelic();
      textIt =
          'Rompi il core rosso. La corruzione ringhia, ma non entra.\nReliquia ottenuta: ${relic?.nameIt ?? 'sconosciuta'}.';
      textEn =
          'You break the red core. Corruption growls, but does not enter.\nRelic obtained: ${relic?.nameEn ?? 'unknown'}.';
    });
  }

  void takeCorruptionCore({required bool purple}) {
    setState(() {
      clearChoices();

      if (purple || hasBaghestEye) {
        final relic = unlockRandomRelic();
        textIt =
            'Prendi la reliquia dal core ${purple ? 'viola' : 'rosso'} senza corromperti.\n${relic?.nameIt ?? ''}';
        textEn =
            'You take the relic from the ${purple ? 'purple' : 'red'} core without corruption.\n${relic?.nameEn ?? ''}';
        return;
      }

      final roll = _random.nextInt(100) + 1;
      if (roll <= 6) {
        activeAllies.clear();
        clearPosteaEliteGuardState();
        _savePermanentProgress();
        textIt = 'Lo prendi con te. La corruzione ti fa massacrare i compagni.';
        textEn =
            'You take it with you. Corruption makes you slaughter your companions.';
      } else if (roll <= 9) {
        playerHp = 0;
        textIt = 'Lo prendi con te. I compagni ti uccidono per fermarti.';
        textEn = 'You take it with you. Your companions kill you to stop you.';
        if (!tryConsumeRebirthBlessing()) finishRun(victorious: false);
      } else {
        final relic = unlockRandomRelic();
        textIt =
            'Lo prendi con te. Dentro c’è una reliquia: ${relic?.nameIt ?? 'sconosciuta'}.';
        textEn =
            'You take it with you. Inside there is a relic: ${relic?.nameEn ?? 'unknown'}.';
      }
    });
  }

  _RelicDef? unlockRandomRelic() {
    final locked = _allRelics
        .where((r) => !r.unlockedByDefault && !unlockedRelicIds.contains(r.id))
        .toList();
    if (locked.isEmpty) return null;
    final relic = locked[_random.nextInt(locked.length)];
    unlockedRelicIds.add(relic.id);
    _savePermanentProgress();
    return relic;
  }

  int combatExpAfterVillagePressure(int baseExp) {
    if (fightsSinceTavernRest <= 3) return baseExp;
    final missedVisits = fightsSinceTavernRest - 3;
    final reduced = baseExp / pow(2, missedVisits);
    return max(1, reduced.ceil()).toInt();
  }

  int enemyPowerScoreFromStats(int hp, int attack, int defense) {
    return hp ~/ 9 + attack * 3 + defense * 2;
  }

  int get playerExpBenchmarkPower {
    return totalDamage * 3 + totalDefense * 2 + playerMaxHp ~/ 9;
  }

  int dungeonExpForEnemy(_EnemyInstance enemy) {
    final levelPressure = max(0, enemy.level - widget.playerLevel);
    final enemyPower = enemy.originalPower > 0
        ? enemy.originalPower
        : enemyPowerScoreFromStats(enemy.maxHp, enemy.attack, enemy.defense);
    final statPressure = max(0, enemyPower - playerExpBenchmarkPower);

    var exp = levelPressure * 10 + statPressure ~/ 5;
    if (exp <= 0 && (enemy.elite || enemy.boss)) {
      exp = 10;
    }

    var multiplier = 1.0;
    final gradePressure = max(0, enemy.grade - widget.playerGrade);
    if (gradePressure > 0) {
      multiplier *= pow(1.2, gradePressure).toDouble();
    }
    if (enemy.elite) multiplier *= 1.3;
    if (enemy.boss) multiplier *= 2.0;

    return max(1, (exp * multiplier).ceil()).toInt();
  }

  int calculateDungeonCombatExp() {
    if (defeatedEnemyExpTotal > 0) {
      return combatExpAfterVillagePressure(defeatedEnemyExpTotal);
    }

    final defeatedCount = max(1, defeatedEnemyNamesIt.length);
    final enemyLevel =
        currentFloor + runGrade + defeatedEliteCount + defeatedBossCount * 2;
    final enemyLevelPressure = max(0, enemyLevel - widget.playerLevel);
    final statPressure = max(
      0,
      defeatedEnemyPowerTotal - playerExpBenchmarkPower,
    );
    var exp = enemyLevelPressure * 10 * defeatedCount + statPressure ~/ 5;
    if (exp <= 0 && (defeatedEliteCount > 0 || defeatedBossCount > 0)) {
      exp = 10 * defeatedCount;
    }

    var multiplier = 1.0;
    final gradePressure = max(0, runGrade - widget.playerGrade);
    if (gradePressure > 0) multiplier *= pow(1.2, gradePressure);
    if (defeatedEliteCount > 0) multiplier *= pow(1.3, defeatedEliteCount);
    if (defeatedBossCount > 0) multiplier *= pow(2.0, defeatedBossCount);
    if (defeatedBossCount == 0 &&
        defeatedEnemyNamesIt.any(
          (name) => name.contains('Boss') || name.contains('Corona'),
        )) {
      multiplier *= 2.0;
    }

    exp = max(1, (exp * multiplier).round()).toInt();
    return combatExpAfterVillagePressure(exp);
  }

  int valleyTrainingExpFor(String result) {
    final base = 180 + currentFloor * 55 + dungeonLevel * 30 + runGrade * 35;
    switch (result) {
      case 'victory':
        return base;
      case 'defeat':
        return (base * 0.58).round();
      case 'timeout':
        return (base * 0.46).round();
    }
    return base ~/ 2;
  }

  void refullAfterValleyTraining() {
    playerHp = playerMaxHp;
    oculumCharges = oculumMaxCharges;
    setPlayerShieldAtLeast(playerMaxHp ~/ 4);
  }

  void grantValleyTrainingExp(String result) {
    if (!valleyTrainingActive || valleyTrainingRewardClaimed) return;
    valleyTrainingRewardClaimed = true;
    gainDungeonExp(valleyTrainingExpFor(result), forceLevelCheck: false);
  }

  void closeValleyTraining() {
    inCombat = false;
    enemyTurnPending = false;
    valleyTrainingActive = false;
    valleyTrainingTurnsLeft = 0;
    enemyParty.clear();
    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    syncPrimaryEnemyFromParty();
    clearChoices();
    saveRunCheckpoint(
      reasonIt: 'Allenamento con Valley chiuso senza morte reale.',
      reasonEn: 'Training with Valley closed without real death.',
    );
  }

  void resolveValleyTrainingVictory() {
    grantValleyTrainingExp('victory');
    refullAfterValleyTraining();
    closeValleyTraining();
    textIt =
        'Valley annuisce. L allenamento e completo.\n'
        'Vita e Oculum vengono ripristinati.\n'
        'L allenamento con Valley ti dona molta esperienza.';
    textEn =
        'Valley nods. The training is complete.\n'
        'HP and Oculum are refilled.\n'
        'Training with Valley grants a lot of experience.';
    addLog('Allenamento con Valley completato: molta EXP.');
  }

  void resolveValleyTrainingDefeat() {
    grantValleyTrainingExp('defeat');
    refullAfterValleyTraining();
    closeValleyTraining();
    textIt =
        'Valley ferma il colpo finale. Non era una morte, era allenamento.\n'
        'Ti rialzi con vita e Oculum ripristinati.\n'
        'Anche nella sconfitta, Valley ti lascia molta esperienza.';
    textEn =
        'Valley stops the final blow. It was not death, it was training.\n'
        'You rise with HP and Oculum refilled.\n'
        'Even in defeat, Valley leaves you a lot of experience.';
    addLog('Allenamento con Valley: sconfitta non reale, EXP assegnata.');
  }

  void resolveValleyTrainingTimeout() {
    grantValleyTrainingExp('timeout');
    refullAfterValleyTraining();
    closeValleyTraining();
    textIt =
        'Valley interrompe l allenamento prima che diventi pericoloso.\n'
        'Vita e Oculum vengono ripristinati.\n'
        'L allenamento interrotto ti lascia esperienza, ma non tutta.';
    textEn =
        'Valley interrupts the training before it becomes dangerous.\n'
        'HP and Oculum are refilled.\n'
        'The interrupted training leaves experience, but not all of it.';
    addLog('Allenamento con Valley interrotto: EXP media alta.');
  }

  bool isRedCorruptedName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('corrotto rosso') ||
        lower.contains('red corrupted') ||
        lower.contains('corruzione rossa');
  }

  void resolveValleyBlooming() {
    if (valleyTrainingActive ||
        valleyBloomResolvedThisFight ||
        !valleyParticipatedInFight) {
      return;
    }
    valleyBloomResolvedThisFight = true;

    final names = List<String>.from(defeatedEnemyNamesIt);
    if (names.isEmpty) {
      textIt +=
          '\nLe sfere di Valley cercano un seme nella carne, ma non trovano nulla.';
      textEn += '\nValley spheres seek a seed in the flesh, but find nothing.';
      return;
    }

    var bloomed = 0;
    for (final name in names) {
      final red = isRedCorruptedName(name);
      if (red || chance(10)) {
        bloomed++;
        if (red) {
          textIt +=
              '\nLa corruzione rossa non resiste alla natura. Valley la costringe a sbocciare.';
          textEn +=
              '\nRed corruption does not resist nature. Valley forces it to bloom.';
        } else {
          textIt +=
              '\nIl corpo del mostro si apre in fiori, rami e carne: Valley lo fa sbocciare.';
          textEn +=
              '\nThe monster body opens into flowers, branches and flesh: Valley makes it bloom.';
        }
      }
    }

    if (bloomed <= 0) {
      textIt +=
          '\nLe sfere di Valley cercano un seme nella carne, ma non trovano nulla.';
      textEn += '\nValley spheres seek a seed in the flesh, but find nothing.';
      return;
    }

    valleyBloomGuards = min(3, valleyBloomGuards + bloomed).toInt();
    textIt += '\nValley sorride con un sorriso impossibilmente spalancato.';
    textEn += '\nValley smiles with an impossibly wide smile.';
    addLog('Valley sorride con un sorriso impossibilmente spalancato.');
  }

  void completeCombatVictory() {
    if (valleyTrainingActive) {
      resolveValleyTrainingVictory();
      return;
    }
    if (posteaGufusEventActive &&
        (posteaGufusEventPhase == 'guards' ||
            posteaGufusEventPhase == 'scientist')) {
      completePosteaCombatVictory();
      return;
    }
    final villageFight = monsterVillageFightActive;
    final defeatedBossFight =
        enemyIsBoss ||
        defeatedBossCount > 0 ||
        defeatedEnemyNamesIt.any(
          (name) => name.contains('Boss') || name.contains('Corona'),
        );
    final defeatedEliteFight =
        enemyIsElite ||
        defeatedEliteCount > 0 ||
        defeatedEnemyNamesIt.any(
          (name) =>
              name.contains('Corrotto Rosso') || name.contains('Oculiano'),
        );

    inCombat = false;
    egoWeaponStacks = 0;
    egoDefenseStacks = 0;
    killStreak++;
    combo++;
    reactionAvailable = true;
    fightsSinceTavernRest++;

    if (defeatedEnemyNamesIt.length > 1) {
      multiEnemyBattlesWon++;
      completeAchievement('win_multi_fight');
    }

    if (defeatedBossFight) {
      completeAchievement('first_boss');
    }

    enemyTurnPending = false;
    progressQuest('kills');
    progressSkillQuest(amount: 1 + skillEventBonus('combat'));

    final partyBonus = max(1, defeatedEnemyNamesIt.length);
    var rewardObser =
        3 * partyBonus + currentFloor + (defeatedBossFight ? 12 : 0);
    var rewardDust = defeatedBossFight
        ? 2 + currentFloor ~/ 3
        : max(0, partyBonus - 1);
    if (villageFight) {
      rewardObser += 12 + currentFloor * 3 + partyBonus * 4;
      rewardDust += max(1, 1 + currentFloor ~/ 3 + partyBonus ~/ 2).toInt();
      fightsSinceTavernRest = 0;
    }

    obserInRun += rewardObser;
    ascensionDustInRun += rewardDust;

    var combatExp = calculateDungeonCombatExp();
    if (villageFight) {
      combatExp = max(
        combatExp + 80 + currentFloor * 20,
        combatExp * 2,
      ).toInt();
    }
    gainDungeonExp(combatExp, forceLevelCheck: false);

    final rawShieldRoomReward = max(
      1,
      currentFloor + defeatedEnemyNamesIt.length + (defeatedBossFight ? 8 : 0),
    );
    final shieldRoomReward = activeCostume?.id == 'vitalium_rebirth_gown'
        ? max(1, rawShieldRoomReward ~/ 2)
        : rawShieldRoomReward;
    gainPlayerShield(shieldRoomReward);

    if (activeCostume?.id == 'vitalium_rebirth_gown') {
      playerHp = playerMaxHp;
    }

    if (chance(
      defeatedBossFight
          ? 90
          : defeatedEnemyNamesIt.length > 1
          ? 42
          : 20,
    )) {
      dropUnique();
    }

    if (defeatedBossFight && chance(45)) {
      tryUnlockRandomArt();
    }

    textIt =
        'Fight vinto.\n\n'
        'Nemici caduti: ${defeatedEnemyNamesIt.join(', ')}\n'
        '+$combatExp EXP'
        '${fightsSinceTavernRest > 3 ? ' (stanchezza da villaggio mancato)' : ''}\n'
        '+$rewardObser Obser\n'
        '+$rewardDust Ascension Dust\n'
        '+$shieldRoomReward Scudo stanza.'
        '${villageFight ? '\nBonus villaggio: ricompensa della lotta clandestina ed EXP aumentata.' : ''}'
        '${activeCostume?.id == 'vitalium_rebirth_gown' ? '\nVeste di Vitalium: HP ripristinati, Scudo fight dimezzato.' : ''}';
    textEn =
        'Fight won.\n\n'
        'Defeated enemies: ${defeatedEnemyNamesEn.join(', ')}\n'
        '+$combatExp EXP'
        '${fightsSinceTavernRest > 3 ? ' (missed village fatigue)' : ''}\n'
        '+$rewardObser Obser\n'
        '+$rewardDust Ascension Dust\n'
        '+$shieldRoomReward room Shield.'
        '${villageFight ? '\nVillage bonus: clandestine fight payout and increased EXP.' : ''}'
        '${activeCostume?.id == 'vitalium_rebirth_gown' ? '\nVitalium Gown: HP restored, fight Shield halved.' : ''}';

    resolveValleyBlooming();
    _OculumDungeonSkinSystem(this).resolveEndFightSpecialMessages();

    if (defeatedEnemyNamesIt.any((name) => name.contains('Baghest'))) {
      baghestBossDefeated = true;
      completeAchievement('baghest_costume_unlocked');
      completeAchievement('baghest_eye_relic_unlocked');
    }

    final defeatedOculian = defeatedEnemyNamesIt.any(
      (name) => name.contains('Oculiano'),
    );
    final coreIsPurple = defeatedOculian || oculianCostume;

    if (defeatedOculian) {
      oculianKills++;
      if (oculianKills >= 3) {
        completeAchievement('three_oculians');
        completeAchievement('oculian_costume_unlocked');
      }
    }

    summonDrownedAlliesFromLastFight();

    defeatedEnemyNamesIt.clear();
    defeatedEnemyNamesEn.clear();
    defeatedEnemyPowerTotal = 0;
    defeatedEnemyExpTotal = 0;
    defeatedBossCount = 0;
    defeatedEliteCount = 0;
    monsterVillageFightActive = false;
    valleyParticipatedInFight = valleyInFight;
    valleyBloomResolvedThisFight = false;
    enemyParty.clear();
    syncPrimaryEnemyFromParty();

    checkPassiveAchievements();
    saveRunCheckpoint(
      reasonIt: 'Fight salvato nel ricordo.',
      reasonEn: 'Fight saved into memory.',
    );

    if (defeatedEliteFight && !gameOver && !villageFight) {
      showCorruptionCoreEvent(purple: coreIsPurple);
    }

    if (defeatedBossFight && !gameOver) {
      dungeonExp = max(dungeonExp, expToNextDungeonLevel);
    }

    if (dungeonExp >= expToNextDungeonLevel && !gameOver) {
      offerDungeonLevelUp(
        reasonIt: 'L’Oculum cresce dopo il fight.',
        reasonEn: 'Oculum grows after the fight.',
      );
    }
  }

  // ================= UI =================

  Color statusColor() {
    if (gameOver && victory) return Colors.greenAccent;
    if (gameOver) return Colors.redAccent;
    if (inCombat) return Colors.orangeAccent;
    return widget.tertiaryColor;
  }

  Widget obserSpriteIcon({double size = 16}) {
    return Image.asset(
      'assets/oculum/obser.png',
      width: size,
      height: size,
      cacheWidth: rasterCacheDimension(size, max: 160),
      cacheHeight: rasterCacheDimension(size, max: 160),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.monetization_on, color: widget.tertiaryColor, size: size),
    );
  }

  Widget statChip(String label, String value, {Color? color, Widget? leading}) {
    final c = color ?? widget.tertiaryColor;
    final cleanLabel = cleanDungeonText(label);
    final cleanValue = cleanDungeonText(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 4)],
          Text(
            '$cleanLabel $cleanValue',
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget bar({
    required String label,
    required int current,
    required int maxValue,
    required Color color,
  }) {
    final safeMax = max(1, maxValue);
    final pct = (current / safeMax).clamp(0.0, 1.0);
    final cleanLabel = cleanDungeonText(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$cleanLabel: $current/$safeMax',
          style: const TextStyle(
            color: Color(0xFFE8E2FF),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: Colors.black,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget compactCard({
    required Widget child,
    Color? borderColor,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    final c = borderColor ?? widget.tertiaryColor;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF0E101A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  String choicePanelTitleIt() {
    switch (choicePanelMode) {
      case 'attack':
        return 'Attacco';
      case 'defense':
        return 'Difesa';
      case 'art':
        return 'Art e Oculum';
      case 'relic':
        return 'Reliquia';
      case 'info':
        return 'Achievement e info';
      case 'achievement':
        return 'Achievement';
      case 'allies':
        return 'Alleati';
      case 'unlocks':
        return 'Sblocchi';
      case 'titles':
        return 'Scelta Titolo';
      case 'skills':
        return 'Skill Oculum';
      default:
        return 'Scelte evento';
    }
  }

  String choicePanelTitleEn() {
    switch (choicePanelMode) {
      case 'attack':
        return 'Attack';
      case 'defense':
        return 'Defense';
      case 'art':
        return 'Arts and Oculum';
      case 'relic':
        return 'Relic';
      case 'info':
        return 'Achievements and info';
      case 'achievement':
        return 'Achievements';
      case 'allies':
        return 'Allies';
      case 'unlocks':
        return 'Unlocks';
      case 'titles':
        return 'Title Choice';
      case 'skills':
        return 'Oculum Skills';
      default:
        return 'Event choices';
    }
  }

  IconData choicePanelIcon() {
    switch (choicePanelMode) {
      case 'attack':
        return Icons.flash_on;
      case 'defense':
        return Icons.shield;
      case 'art':
        return Icons.auto_fix_high;
      case 'info':
        return Icons.info_outline;
      case 'achievement':
        return Icons.emoji_events;
      case 'allies':
        return Icons.groups;
      case 'unlocks':
        return Icons.lock_open;
      case 'titles':
        return Icons.workspace_premium;
      case 'skills':
        return Icons.auto_fix_high;
      default:
        return Icons.auto_awesome;
    }
  }

  Color choicePanelColor() {
    switch (choicePanelMode) {
      case 'attack':
        return Colors.amber;
      case 'defense':
        return Colors.greenAccent;
      case 'art':
        return const Color(0xFFA78BFA);
      case 'info':
        return Colors.lightBlueAccent;
      case 'achievement':
        return Colors.amber;
      case 'allies':
        return Colors.tealAccent;
      case 'unlocks':
        return const Color(0xFF8B5CF6);
      case 'titles':
        return const Color(0xFFFFD36A);
      case 'skills':
        return const Color(0xFFA78BFA);
      default:
        return widget.tertiaryColor;
    }
  }

  Widget modernActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    bool compact = false,
  }) {
    if (onPressed == null) return const SizedBox.shrink();

    final c = color ?? widget.tertiaryColor;
    final cleanLabel = cleanDungeonText(label);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxButtonWidth = constraints.maxWidth.isFinite
            ? min(constraints.maxWidth, compact ? 220.0 : 292.0)
            : (compact ? 220.0 : 292.0);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxButtonWidth),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Opacity(
              opacity: 1,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: c, size: compact ? 15 : 17),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        cleanLabel,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 11.0 : 12.2,
                          height: 1.08,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget collapsiblePanel({
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
    Color? color,
    String? trailing,
  }) {
    final c = color ?? widget.tertiaryColor;
    final cleanTitle = cleanDungeonText(title);
    final cleanTrailing = trailing == null ? null : cleanDungeonText(trailing);
    return compactCard(
      borderColor: c,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(icon, color: c, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cleanTitle,
                      style: TextStyle(
                        color: c,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (cleanTrailing != null) ...[
                    Text(
                      cleanTrailing,
                      style: const TextStyle(
                        color: Color(0xFFBFB7DD),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down, color: c),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  String spriteKindForElement(String elementId, String name) {
    final lower = name.toLowerCase();
    if (lower.contains('valley')) return 'valley';
    if (lower.contains('vitalium')) return 'vitalium';
    if (elementId == 'nullum' ||
        lower.contains('null') ||
        lower.contains('fateless')) {
      return 'dotted_eye';
    }
    if (lower.contains('patalpa')) return 'patalpa';
    if (lower.contains('mimic') || lower.contains('mimico')) return 'mimic';
    if (lower.contains('incubo') || lower.contains('nightmare')) {
      return 'nightmare';
    }
    if (lower.contains('slime') && lower.contains('elmetto')) {
      return 'slime_helmeted';
    }
    if (elementId == 'slime' || lower.contains('slime')) return 'slime';
    if (lower.contains('rhino') ||
        lower.contains('rinoceronte') ||
        lower.contains('costrutto')) {
      return 'rock_rhino';
    }
    if (lower.contains('mercante') || lower.contains('merchant')) {
      return 'merchant';
    }
    if (lower.contains('alchimista') || lower.contains('alchemist')) {
      return 'alchemist';
    }
    if (lower.contains('duellante') ||
        lower.contains('guerriero') ||
        lower.contains('warrior')) {
      return 'warrior';
    }
    if (elementId == 'postea' ||
        lower.contains('postea') ||
        lower.contains('scienziato') ||
        lower.contains('scientist')) {
      return 'warrior';
    }
    if (lower.contains('gufus') || lower.contains('falena')) return 'winged';
    if (lower.contains('corona') || lower.contains('boss')) {
      return 'legendary_eye_knight';
    }
    if (lower.contains('cultista') || lower.contains('cultist')) {
      return 'cultist';
    }
    if (lower.contains('pedina') || lower.contains('pawn')) return 'pawn';
    if (lower.contains('oculiano') || lower.contains('oculian')) return 'eye';
    if (lower.contains('osso') || lower.contains('bone')) {
      return 'construct';
    }
    if (elementId == 'shadow') return 'horned';
    if (elementId == 'metal' ||
        elementId == 'earth' ||
        elementId == 'crystal' ||
        elementId == 'bone' ||
        elementId == 'vapium') {
      return 'construct';
    }
    if (elementId == 'wind' ||
        elementId == 'sound' ||
        elementId == 'moon' ||
        elementId == 'dream') {
      return 'winged';
    }
    if (elementId == 'fire' ||
        elementId == 'lava' ||
        elementId == 'lightning' ||
        elementId == 'blood') {
      return 'horned';
    }
    if (elementId == 'flora' ||
        elementId == 'poison' ||
        lower.contains('patalpa')) {
      return 'beast';
    }
    return 'humanoid';
  }

  String itemSpriteKind(String type, String elementId, String name) {
    final lower = name.toLowerCase();
    if (type == 'weapon') {
      if ((lower.contains('lama') || lower.contains('blade')) &&
          (lower.contains('scudo') || lower.contains('shield'))) {
        return 'blade_shield';
      }
      if (lower.contains('gadget')) return 'gadget_weapon';
      return 'weapon';
    }
    if (type == 'costume') return 'armor';
    if (type == 'relic') return 'relic';
    if (type == 'art') return 'art';
    if (lower.contains('vitalium')) return 'vitalium';
    if (type == 'drop') return 'drop';
    return spriteKindForElement(elementId, name);
  }

  Color get playerEyeColor {
    if (activeArt != null) return elementColor(activeArt!.elementId);
    return Color.lerp(Colors.white, widget.tertiaryColor, 0.28)!;
  }

  String get playerWeaponSpriteKind {
    if (starterWeapon == null) return '';
    return itemSpriteKind(
      'weapon',
      starterWeapon!.elementId,
      starterWeapon!.nameIt,
    );
  }

  Color get playerWeaponColor {
    if (starterWeapon == null) return Colors.white;
    return elementColor(starterWeapon!.elementId);
  }

  int get playerWeaponSeed {
    if (starterWeapon == null) return 0;
    return stableSpriteSeed('weapon:${starterWeapon!.id}');
  }

  String get playerArmorSpriteKind {
    if (activeCostume == null) return '';
    return activeCostume!.id;
  }

  Color get playerArmorColor {
    if (activeCostume == null) return Colors.transparent;
    return elementColor(activeCostume!.elementId);
  }

  int get playerArmorSeed {
    if (activeCostume == null) return 0;
    return stableSpriteSeed('costume:${activeCostume!.id}');
  }

  String safeSpriteLabel(String value, String fallback) {
    final trimmed = cleanDungeonText(value).trim();
    if (trimmed.isEmpty || trimmed == '???') return fallback;
    return trimmed;
  }

  List<String> get playerSpriteKinds {
    final skins = <String>[
      'humanoid',
      'horned',
      'winged',
      'beast',
      'construct',
      'slime',
      'eye',
      'art',
    ];
    if (completedAchievementIds.contains('pawn_relic_unlocked') ||
        unlockedRelicIds.contains('pawn_guardiano')) {
      skins.add('pawn');
    }
    if (completedAchievementIds.contains('three_oculians') ||
        unlockedCostumeIds.contains('oculian_eye_mantle')) {
      skins.add('relic');
    }
    return skins;
  }

  String get currentPlayerSpriteKind {
    if (selectedSkinId != 'base_oculum') return activeSkin.spriteKind;
    if (activeCharacterOrigin != null) {
      return activeCharacterOrigin!.spriteKind;
    }
    final skins = playerSpriteKinds;
    return skins[playerSpriteShape % skins.length];
  }

  bool spriteKindSupportsEquipment(String kind) {
    final value = kind.toLowerCase();
    return value == 'humanoid' ||
        value.startsWith('human_') ||
        value == 'cultist' ||
        value == 'legendary_eye_knight' ||
        value == 'relic';
  }

  bool get currentPlayerSkinHidesEquipment =>
      currentPlayerSpriteKind == 'pawn' ||
      activeSkin.hideEquipment ||
      activeSkin.monsterSkin ||
      !spriteKindSupportsEquipment(currentPlayerSpriteKind);

  int stableSpriteSeed(String value) {
    var hash = 17;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  int get playerAppearanceLayers {
    var layers = 0;
    if (starterWeapon != null) layers++;
    if (activeCostume != null) layers++;
    if (activeRelic != null) layers++;
    layers += attachedDrops.length.clamp(0, 2);
    return layers;
  }

  Color get playerAppearanceColor {
    if (selectedSkinId == 'base_oculum' && activeCharacterOrigin != null) {
      return activeCharacterOrigin!.primaryColor;
    }
    final colors = [
      widget.tertiaryColor,
      elementColor(activeElementId),
      starterWeapon == null
          ? widget.primaryColor
          : elementColor(starterWeapon!.elementId),
      activeArt == null
          ? widget.secondaryColor
          : elementColor(activeArt!.elementId),
      activeRelic == null ? const Color(0xFFFFD36A) : const Color(0xFFA78BFA),
    ];
    return colors[playerSpriteAccent % colors.length];
  }

  List<String> appearanceLines() {
    final lines = <String>[];
    if (starterWeapon != null) {
      lines.add(
        '${t('Arma', 'Weapon')}: ${widget.linguaInglese ? starterWeapon!.nameEn : starterWeapon!.nameIt}',
      );
    }
    if (activeArt != null) {
      lines.add(
        'Art: ${widget.linguaInglese ? activeArt!.nameEn : activeArt!.nameIt} (${t('solo occhi/energia', 'eyes/energy only')})',
      );
    }
    if (activeCostume != null) {
      lines.add(
        '${t('Costume', 'Costume')}: ${widget.linguaInglese ? activeCostume!.nameEn : activeCostume!.nameIt}',
      );
    }
    if (activeRelic != null) {
      lines.add(
        '${t('Reliquia', 'Relic')}: ${widget.linguaInglese ? activeRelic!.nameEn : activeRelic!.nameIt}',
      );
    }
    for (final drop in attachedDrops.take(4)) {
      lines.add(
        '${t('Forma drop', 'Drop shape')}: ${widget.linguaInglese ? drop.nameEn : drop.nameIt}',
      );
    }
    return lines.isEmpty
        ? [t('Aspetto base modificabile.', 'Editable base appearance.')]
        : lines;
  }

  String? playerDungeonSpriteAssetForKind(String kind) {
    switch (kind) {
      case 'humanoid':
      case 'human_short_hair':
      case 'human_masc_hair':
        return 'assets/oculum/sprites/male_character_oculum.png';
      case 'human_fem_hair':
      case 'human_long_hair':
        return 'assets/oculum/sprites/female_character_oculum.png';
      case 'human_oculian_male':
        return 'assets/oculum/sprites/male_character_oculian.png';
      case 'human_oculian_female':
        return 'assets/oculum/sprites/female_character_oculian_alt.png';
      case 'human_oculian_female_ritual':
        return 'assets/oculum/sprites/female_charcter_oculian.png';
      case 'pawn':
        return 'assets/oculum/sprites/Pawn.png';
      case 'cultist':
        return 'assets/oculum/sprites/Cultist_of_Purple_Eyes.png';
      case 'eye':
      case 'relic':
      case 'relic_eye':
        return 'assets/oculum/sprites/Occhio_della_Reliquia.png';
    }
    return null;
  }

  String canonicalDungeonSpriteAssetPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final lower = normalized.toLowerCase();
    switch (lower) {
      case 'assets/oculum_dungeon/generated_sprites/npc/gufus_leviante.png':
        return 'assets/oculum_dungeon/generated_sprites/npc/Gufus_Leviante.png';
      case 'assets/oculum_dungeon/generated_sprites/enemies/rock rhyno.png':
      case 'assets/oculum_dungeon/generated_sprites/enemies/rock_rhyno.png':
        return 'assets/oculum_dungeon/generated_sprites/enemies/rock_rhino.png';
      case 'assets/oculum_dungeon/generated_sprites/enemies/uomo in posizione fetale.png':
        return 'assets/oculum_dungeon/generated_sprites/enemies/uomo_in_posizione_fetale_refit.png';
      default:
        return normalized;
    }
  }

  String? _monsterArtworkAssetOrNull(String? path) {
    if (path == null) return null;
    final normalized = canonicalDungeonSpriteAssetPath(path);
    if (normalized.startsWith('assets/oculum/') ||
        normalized.startsWith('assets/oculum_dungeon/generated_sprites/')) {
      return normalized;
    }
    return null;
  }

  String? monsterDungeonSpriteAsset(
    String elementId,
    String name, [
    String? spriteAssetPath,
  ]) {
    final exact = _monsterArtworkAssetOrNull(spriteAssetPath);
    if (exact != null) return exact;

    final lower = name.toLowerCase();
    String? candidate;

    if (lower.contains('uomo in posizione fetale') || lower.contains('fetal')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/uomo_in_posizione_fetale_refit.png';
    } else if (lower.contains('decapitato') ||
        lower.contains('senza testa') ||
        lower.contains('headless')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/headless_man_blood.png';
    } else if (lower.contains('rock rhino')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/rock_rhino.png';
    } else if (lower.contains('scienziato di postea') ||
        lower.contains('postea scientist')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/postea_scientist.png';
    } else if (lower.contains('gufus')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/npc/Gufus_Leviante.png';
    } else if ((lower.contains('guardia') && lower.contains('postea')) ||
        lower.contains('postea elite guard')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/npc/postea_elite_guard.png';
    } else if (lower.contains('kooba')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/npc/kooba_glimmer_moralist.png';
    } else if (lower.contains('slime') && lower.contains('elmetto')) {
      candidate = 'assets/oculum/sprites/Slime.png';
    } else if (lower.contains('slime')) {
      candidate = 'assets/oculum/sprites/Slime.png';
    } else if (lower.contains('occhio caduto') ||
        lower.contains('fallen eye')) {
      candidate = 'assets/oculum/sprites/Occhio_della_Reliquia.png';
    } else if (lower.contains('vero incubo') ||
        lower.contains('true nightmare')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/true_nightmare_without_awakening.png';
    } else if (lower.contains('mimic') || lower.contains('mimico')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/shadow_mimic.png';
    } else if (lower.contains('incubo') || lower.contains('nightmare')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/infant_nightmare_without_awakening.png';
    } else if (lower.contains('patalpa')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/patalpa_dolce.png';
    } else if (lower.contains('bilancia') ||
        lower.contains('scale guide') ||
        lower.contains('candela nera') ||
        lower.contains('black debt')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/npc/karma_split_guide.png';
    } else if (elementId == 'postea' || lower.contains('postea')) {
      candidate = 'assets/oculum/sprites/male_character_oculian.png';
    } else if (lower.contains('cultista') || lower.contains('cultist')) {
      candidate = 'assets/oculum/sprites/Cultist_of_Purple_Eyes.png';
    } else if (elementId == 'oculum' ||
        lower.contains('oculiano') ||
        lower.contains('oculian')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/oculiano.png';
    } else if (elementId == 'nullum' ||
        lower.contains('null') ||
        lower.contains('fateless')) {
      candidate =
          'assets/oculum_dungeon/generated_sprites/enemies/null_fateless.png';
    } else if (elementId == 'bone' ||
        lower.contains('corona') ||
        lower.contains('boss')) {
      candidate = 'assets/oculum/sprites/Crown_of_Bones.png';
    }

    return _monsterArtworkAssetOrNull(candidate);
  }

  bool allySpriteFacesRight(_GoodNpc ally) {
    return true;
  }

  bool enemySpriteFacesRight(_EnemyInstance enemy) {
    return false;
  }

  String? dungeonArmorAssetForKind(String armorKind) {
    final id = armorKind.toLowerCase();
    if (id.contains('bone') || id.contains('button')) {
      return null;
    }
    if (id.contains('oculian') || id.contains('oculum')) {
      return null;
    }
    return null;
  }

  Widget dungeonSpriteArt({
    required Color color,
    required int seed,
    required String kind,
    required Color eyeColor,
    required int layers,
    required bool flip,
    String? assetPath,
    String weaponKind = '',
    Color weaponColor = Colors.white,
    int weaponSeed = 0,
    String armorKind = '',
    Color armorColor = Colors.transparent,
    int armorSeed = 0,
    String? armorAssetPath,
    double cacheLogicalSize = 128,
  }) {
    final fallback = CustomPaint(
      isComplex: true,
      willChange: false,
      painter: _OculumSpritePainter(
        color: color,
        seed: seed,
        kind: kind,
        eyeColor: eyeColor,
        layers: layers,
        weaponKind: weaponKind,
        weaponColor: weaponColor,
        weaponSeed: weaponSeed,
        armorKind: armorKind,
        armorColor: armorColor,
        armorSeed: armorSeed,
      ),
    );
    Widget assetImage(String path, Widget errorFallback) {
      final cacheSize = rasterCacheDimension(cacheLogicalSize, max: 512);
      return Image.asset(
        path,
        fit: BoxFit.contain,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stackTrace) => errorFallback,
      );
    }

    final child = assetPath == null
        ? fallback
        : Stack(
            fit: StackFit.expand,
            children: [
              assetImage(assetPath, fallback),
              if (armorAssetPath != null && armorKind.isNotEmpty)
                assetImage(armorAssetPath, const SizedBox.shrink()),
            ],
          );
    if (!flip) return child;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
      child: child,
    );
  }

  Widget spriteBox({
    required String label,
    required Color color,
    required String kind,
    required int seed,
    int layers = 0,
    double size = 74,
    bool flip = false,
    Color? eyeColor,
    String weaponKind = '',
    Color weaponColor = Colors.white,
    int weaponSeed = 0,
    String armorKind = '',
    Color armorColor = Colors.transparent,
    int armorSeed = 0,
    String? assetPath,
    String? armorAssetPath,
  }) {
    final cardWidth = max(size + 30, 108.0);
    final cleanLabel = cleanDungeonText(label);
    final spriteLabel = cleanLabel.replaceAll('\n', ' ').trim();

    return SizedBox(
      width: cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0C16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.55)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: dungeonSpriteArt(
                        color: color,
                        seed: seed,
                        kind: kind,
                        eyeColor: eyeColor ?? Colors.white,
                        layers: layers,
                        weaponKind: weaponKind,
                        weaponColor: weaponColor,
                        weaponSeed: weaponSeed,
                        armorKind: armorKind,
                        armorColor: armorColor,
                        armorSeed: armorSeed,
                        flip: flip,
                        assetPath: assetPath,
                        armorAssetPath: armorAssetPath,
                        cacheLogicalSize: size,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Tooltip(
            message: spriteLabel,
            child: SizedBox(
              width: cardWidth,
              height: 30,
              child: Text(
                cleanLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8E2FF),
                  fontSize: 11,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget miniHpBar({
    required int current,
    required int maxValue,
    required Color color,
    double width = 68,
  }) {
    final safeMax = max(1, maxValue);
    final safeCurrent = current.clamp(0, safeMax).toInt();
    final pct = (safeCurrent / safeMax).clamp(0.0, 1.0);

    return SizedBox(
      width: width,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: const Color(0xFF070812),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$safeCurrent/$safeMax',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDCD6F5),
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget battleActor({
    required String label,
    required Color color,
    required String kind,
    required int seed,
    required bool faceRight,
    int layers = 0,
    int? hp,
    int? maxHp,
    double spriteSize = 78,
    Color? eyeColor,
    String weaponKind = '',
    Color weaponColor = Colors.white,
    int weaponSeed = 0,
    String armorKind = '',
    Color armorColor = Colors.transparent,
    int armorSeed = 0,
    String? assetPath,
    String? armorAssetPath,
  }) {
    final actorWidth = max(spriteSize + 26, 92.0);
    final cleanLabel = cleanDungeonText(label);
    return SizedBox(
      width: actorWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: spriteSize,
            height: spriteSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: dungeonSpriteArt(
                    color: color,
                    seed: seed,
                    kind: kind,
                    eyeColor: eyeColor ?? Colors.white,
                    layers: layers,
                    weaponKind: weaponKind,
                    weaponColor: weaponColor,
                    weaponSeed: weaponSeed,
                    armorKind: armorKind,
                    armorColor: armorColor,
                    armorSeed: armorSeed,
                    flip: !faceRight,
                    assetPath: assetPath,
                    armorAssetPath: armorAssetPath,
                  ),
                ),
              ],
            ),
          ),
          if (hp != null && maxHp != null) ...[
            const SizedBox(height: 4),
            miniHpBar(current: hp, maxValue: maxHp, color: color),
          ],
          const SizedBox(height: 3),
          Text(
            cleanLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF4F0FF),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
        ],
      ),
    );
  }

  Widget stageQuickButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final active = onPressed != null;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Opacity(
          opacity: active ? 1 : 0.34,
          child: Container(
            width: 38,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.52)),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
        ),
      ),
    );
  }

  List<Widget> liveAllyActors() {
    final allies = <Widget>[];
    if (valleyInFight) {
      allies.add(
        battleActor(
          label:
              'Valley\n${t('turni', 'turns')} $valleyTurnsLeft • ${t('sbocciati', 'bloomed')} $valleyBloomGuards',
          color: const Color(0xFF55B86B),
          kind: 'valley',
          seed: stableSpriteSeed('ally:valley'),
          faceRight: true,
          layers: 3,
          hp: valleyHp,
          maxHp: valleyMaxHp,
          spriteSize: 62,
        ),
      );
    }
    for (final ally in activeAllies.take(4)) {
      if (ally.id == 'valley_child_of_mother_nature' && valleyInFight) {
        continue;
      }
      allies.add(
        battleActor(
          label: widget.linguaInglese ? ally.nameEn : ally.nameIt,
          color: elementColor(ally.elementId),
          kind: spriteKindForElement(ally.elementId, ally.nameIt),
          seed: stableSpriteSeed('ally:${ally.id}'),
          faceRight: allySpriteFacesRight(ally),
          layers: allySpriteLayers(ally),
          hp: isPosteaEliteGuard(ally) ? allyTrackedHp(ally) : null,
          maxHp: isPosteaEliteGuard(ally) ? allyTrackedMaxHp(ally) : null,
          spriteSize: isPosteaEliteGuard(ally) ? 58 : 55,
          assetPath: monsterDungeonSpriteAsset(ally.elementId, ally.nameIt),
        ),
      );
    }
    if (skeletonHandsHp > 0) {
      allies.add(
        battleActor(
          label: t('Mani scheletro', 'Skeleton hands'),
          color: elementColor('bone'),
          kind: 'construct',
          seed: stableSpriteSeed('ally:skeletonHands'),
          faceRight: true,
          layers: 2,
          hp: skeletonHandsHp,
          maxHp: skeletonHandsMaxHp,
          spriteSize: 55,
        ),
      );
    }
    if (cipoSerpentHp > 0) {
      allies.add(
        battleActor(
          label: 'Serpente di Cipo',
          color: const Color(0xFF69F08A),
          kind: 'serpent',
          seed: stableSpriteSeed('ally:cipo_serpent'),
          faceRight: true,
          layers: 3,
          hp: cipoSerpentHp,
          maxHp: cipoSerpentMaxHp,
          spriteSize: 62,
        ),
      );
    }
    if (egoShieldHp > 0) {
      allies.add(
        battleActor(
          label: "Scudo dell'Io",
          color: const Color(0xFFFFD36A),
          kind: 'construct',
          seed: stableSpriteSeed('ally:ego_shield'),
          faceRight: true,
          layers: 2,
          hp: egoShieldHp,
          maxHp: max(1, totalCm + 10).toInt(),
          spriteSize: 55,
        ),
      );
    }
    if (floralGuardCharges > 0) {
      allies.add(
        battleActor(
          label: 'Umani floreali x$floralGuardCharges',
          color: const Color(0xFFFF8CCB),
          kind: 'flora',
          seed: stableSpriteSeed('ally:floral_guards'),
          faceRight: true,
          layers: 2,
          hp: floralGuardCharges,
          maxHp: max(1, floralGuardCharges),
          spriteSize: 55,
        ),
      );
    }
    if (pawnHp > 0) {
      allies.add(
        battleActor(
          label: t('Pedina', 'Pawn'),
          color: widget.tertiaryColor,
          kind: 'pawn',
          seed: stableSpriteSeed('ally:pawn'),
          faceRight: true,
          layers: 2,
          hp: pawnHp,
          maxHp: pawnMaxHp,
          spriteSize: 55,
        ),
      );
    }
    return allies.take(5).toList();
  }

  int estimatedVictoryChance() {
    if (!inCombat || enemyParty.isEmpty) return 100;
    final livingEnemies = enemyParty.where((e) => e.hp > 0).toList();
    if (livingEnemies.isEmpty) return 100;

    final allyHp =
        activeAllies.length * 35 +
        (pawnHp > 0 ? pawnHp + pawnShield : 0) +
        (posteaEliteGuardHp > 0
            ? posteaEliteGuardHp +
                  posteaEliteGuardShield +
                  posteaEliteGuardAttack * 3
            : 0) +
        (valleyInFight ? valleyHp + valleyAttack * 5 + valleyDefense * 4 : 0);
    final oculumPower =
        oculumCharges * 18 +
        (activeArt != null ? 22 : 0) +
        (canUseRelicOpen() ? 28 : 0) +
        (canUseRelicSkill() ? 16 : 0);
    final playerPower =
        playerHp +
        playerShield +
        setShieldBonus +
        allyHp +
        totalDamage * 5 +
        totalDefense * 4 +
        oculumPower +
        setCritBonus * 3 +
        setVictoryChanceBonus * 9;

    var enemyPower = 0;
    for (final enemy in livingEnemies) {
      enemyPower +=
          enemy.hp + enemy.maxHp ~/ 2 + enemy.attack * 5 + enemy.defense * 4;
      if (enemy.elite) enemyPower += 35;
      if (enemy.boss) enemyPower += 85;
    }

    final chanceValue = (playerPower / max(1, playerPower + enemyPower) * 100)
        .round();
    return chanceValue.clamp(5, 95).toInt();
  }

  void showAppearanceEditor() {
    setState(() {
      clearChoices(mode: 'event');
      textIt =
          'Aspetto e sprite.\n\n'
          'Il tuo sprite cambia con arma, costume, reliquia e drop con forma. Le Art restano sugli occhi e sull\'energia per evitare overlay buggati.\n\n'
          'Skin disponibili: ${playerSpriteKinds.join(', ')}.\n'
          'Nota: la skin Pawn nasconde arma e armatura per evitare bug visuali.\n\n'
          '${appearanceLines().join('\n')}';
      textEn =
          'Appearance and sprite.\n\n'
          'Your sprite changes with weapon, costume, relic and shaped drops. Arts stay on eyes and energy to avoid broken overlays.\n\n'
          'Available skins: ${playerSpriteKinds.join(', ')}.\n'
          'Note: the Pawn skin hides weapon and armor to avoid visual bugs.\n\n'
          '${appearanceLines().join('\n')}';
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Inserisci nome',
          labelEn: 'Enter name',
          icon: Icons.edit,
          color: const Color(0xFF7EE7C8),
          onPressed: () => promptPlayerNameInput(),
        ),
      );
      eventChoices.add(
        _DungeonChoice(
          labelIt: showSpriteCodex
              ? 'Chiudi pagina sprite'
              : 'Apri pagina sprite',
          labelEn: showSpriteCodex ? 'Close sprite page' : 'Open sprite page',
          icon: Icons.grid_view,
          color: const Color(0xFFA78BFA),
          onPressed: () => setState(() => showSpriteCodex = !showSpriteCodex),
        ),
      );
      eventChoices.add(
        _DungeonChoice(
          labelIt: classicCombatView
              ? 'Usa fight con sprite vivi'
              : 'Usa visuale classica',
          labelEn: classicCombatView
              ? 'Use live sprite fight'
              : 'Use classic view',
          icon: classicCombatView
              ? Icons.sports_martial_arts
              : Icons.view_agenda,
          color: const Color(0xFFA78BFA),
          onPressed: () =>
              setState(() => classicCombatView = !classicCombatView),
        ),
      );
    });
  }

  Widget buildSpriteStage(Color c) {
    if (!showSpritePanel) return const SizedBox.shrink();
    final enemies = enemyParty.where((e) => e.hp > 0).take(5).toList();
    final allyActors = liveAllyActors();

    if (!inCombat) {
      final equippedSprites = <Widget>[];
      final shapedDrops = inventoryDrops
          .where(
            (drop) =>
                drop.nameIt.toLowerCase().contains('forma') ||
                drop.nameEn.toLowerCase().contains('shape') ||
                drop.damageBonus != 0 ||
                drop.defenseBonus != 0 ||
                drop.resistBonus != 0,
          )
          .take(enemies.isEmpty ? 4 : 2)
          .toList();

      return compactCard(
        borderColor: c,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: c, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('Sprite vivi', 'Live sprites'),
                    style: TextStyle(color: c, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: t('Modifica aspetto', 'Edit appearance'),
                  onPressed: showAppearanceEditor,
                  icon: Icon(Icons.brush, color: c, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 124,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  spriteBox(
                    label: safeSpriteLabel(
                      playerNameInRun,
                      t('Personaggio', 'Character'),
                    ),
                    color: playerAppearanceColor,
                    kind: currentPlayerSpriteKind,
                    seed: stableSpriteSeed(
                      'player:${safeSpriteLabel(playerNameInRun, 'character')}',
                    ),
                    layers: playerAppearanceLayers,
                    eyeColor: playerEyeColor,
                    weaponKind: currentPlayerSkinHidesEquipment
                        ? ''
                        : playerWeaponSpriteKind,
                    weaponColor: playerWeaponColor,
                    weaponSeed: playerWeaponSeed,
                    armorKind: currentPlayerSkinHidesEquipment
                        ? ''
                        : playerArmorSpriteKind,
                    armorColor: playerArmorColor,
                    armorSeed: playerArmorSeed,
                    assetPath: playerDungeonSpriteAssetForKind(
                      currentPlayerSpriteKind,
                    ),
                    armorAssetPath: dungeonArmorAssetForKind(
                      playerArmorSpriteKind,
                    ),
                  ),
                  ...equippedSprites,
                  for (final enemy in enemies)
                    spriteBox(
                      label: widget.linguaInglese ? enemy.nameEn : enemy.nameIt,
                      color: elementColor(enemy.elementId),
                      kind: spriteKindForElement(enemy.elementId, enemy.nameIt),
                      seed: stableSpriteSeed(
                        'enemy:${enemy.monsterId ?? enemy.nameIt}:${enemy.elementId}:${enemy.level}:${enemy.grade}',
                      ),
                      layers: enemy.elite
                          ? 2
                          : enemy.boss
                          ? 4
                          : 1,
                      size: enemy.boss
                          ? 82
                          : enemy.elite
                          ? 70
                          : 58,
                      assetPath: monsterDungeonSpriteAsset(
                        enemy.elementId,
                        enemy.nameIt,
                        enemy.spriteAssetPath,
                      ),
                      flip: !enemySpriteFacesRight(enemy),
                    ),
                  for (final drop in shapedDrops)
                    spriteBox(
                      label: widget.linguaInglese ? drop.nameEn : drop.nameIt,
                      color: elementColor(drop.elementId),
                      kind: spriteKindForElement(drop.elementId, drop.nameIt),
                      seed: stableSpriteSeed(
                        'drop:${drop.elementId}:${drop.id}',
                      ),
                      layers: 2,
                      size: 58,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (classicCombatView) {
      return compactCard(
        borderColor: c,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mediaSize = MediaQuery.of(context).size;
            final phoneLandscape =
                mediaSize.shortestSide < 600 &&
                mediaSize.width > mediaSize.height;
            final narrow = constraints.maxWidth < 430;
            final actorSize = phoneLandscape
                ? 50.0
                : narrow
                ? 44.0
                : 54.0;
            final stageHeight = phoneLandscape
                ? 172.0
                : narrow
                ? 166.0
                : 184.0;

            final partyActors = <Widget>[
              battleActor(
                label: safeSpriteLabel(
                  playerNameInRun,
                  t('Personaggio', 'Character'),
                ),
                color: playerAppearanceColor,
                kind: currentPlayerSpriteKind,
                seed: stableSpriteSeed(
                  'player:${safeSpriteLabel(playerNameInRun, 'character')}',
                ),
                faceRight: true,
                layers: playerAppearanceLayers,
                hp: playerHp,
                maxHp: playerMaxHp,
                spriteSize: actorSize + 8,
                eyeColor: playerEyeColor,
                weaponKind: currentPlayerSkinHidesEquipment
                    ? ''
                    : playerWeaponSpriteKind,
                weaponColor: playerWeaponColor,
                weaponSeed: playerWeaponSeed,
                armorKind: currentPlayerSkinHidesEquipment
                    ? ''
                    : playerArmorSpriteKind,
                armorColor: playerArmorColor,
                armorSeed: playerArmorSeed,
                assetPath: playerDungeonSpriteAssetForKind(
                  currentPlayerSpriteKind,
                ),
                armorAssetPath: dungeonArmorAssetForKind(playerArmorSpriteKind),
              ),
            ];

            if (valleyInFight) {
              partyActors.add(
                battleActor(
                  label: 'Valley',
                  color: const Color(0xFF55B86B),
                  kind: 'valley',
                  seed: stableSpriteSeed('ally:valley'),
                  faceRight: true,
                  layers: 3,
                  hp: valleyHp,
                  maxHp: valleyMaxHp,
                  spriteSize: actorSize,
                ),
              );
            }

            for (final ally in activeAllies.take(4)) {
              if (ally.id == 'valley_child_of_mother_nature' && valleyInFight) {
                continue;
              }
              final trackedHp = allyTrackedHp(ally);
              final trackedMax = allyTrackedMaxHp(ally);
              partyActors.add(
                battleActor(
                  label: widget.linguaInglese ? ally.nameEn : ally.nameIt,
                  color: elementColor(ally.elementId),
                  kind: spriteKindForElement(ally.elementId, ally.nameIt),
                  seed: stableSpriteSeed('ally:${ally.id}'),
                  faceRight: allySpriteFacesRight(ally),
                  layers: allySpriteLayers(ally),
                  hp: trackedHp,
                  maxHp: trackedMax,
                  spriteSize: isPosteaEliteGuard(ally)
                      ? actorSize + 6
                      : actorSize,
                  assetPath: monsterDungeonSpriteAsset(
                    ally.elementId,
                    ally.nameIt,
                  ),
                ),
              );
            }

            if (skeletonHandsHp > 0) {
              partyActors.add(
                battleActor(
                  label: t('Mani', 'Hands'),
                  color: elementColor('bone'),
                  kind: 'construct',
                  seed: stableSpriteSeed('ally:skeletonHands'),
                  faceRight: true,
                  layers: 2,
                  hp: skeletonHandsHp,
                  maxHp: skeletonHandsMaxHp,
                  spriteSize: actorSize,
                ),
              );
            }
            if (cipoSerpentHp > 0) {
              partyActors.add(
                battleActor(
                  label: t('Serpente', 'Serpent'),
                  color: const Color(0xFF69F08A),
                  kind: 'serpent',
                  seed: stableSpriteSeed('ally:cipo_serpent'),
                  faceRight: true,
                  layers: 3,
                  hp: cipoSerpentHp,
                  maxHp: cipoSerpentMaxHp,
                  spriteSize: actorSize + 8,
                ),
              );
            }
            if (egoShieldHp > 0) {
              partyActors.add(
                battleActor(
                  label: t('Scudo Io', 'Self Shield'),
                  color: const Color(0xFFFFD36A),
                  kind: 'construct',
                  seed: stableSpriteSeed('ally:ego_shield'),
                  faceRight: true,
                  layers: 2,
                  hp: egoShieldHp,
                  maxHp: max(1, totalCm + 10).toInt(),
                  spriteSize: actorSize,
                ),
              );
            }
            if (floralGuardCharges > 0) {
              partyActors.add(
                battleActor(
                  label: t(
                    'Fiori x$floralGuardCharges',
                    'Flowers x$floralGuardCharges',
                  ),
                  color: const Color(0xFFFF8CCB),
                  kind: 'flora',
                  seed: stableSpriteSeed('ally:floral_guards'),
                  faceRight: true,
                  layers: 2,
                  hp: floralGuardCharges,
                  maxHp: max(1, floralGuardCharges),
                  spriteSize: actorSize,
                ),
              );
            }
            if (pawnHp > 0) {
              partyActors.add(
                battleActor(
                  label: t('Pedina', 'Pawn'),
                  color: widget.tertiaryColor,
                  kind: 'pawn',
                  seed: stableSpriteSeed('ally:pawn'),
                  faceRight: true,
                  layers: 2,
                  hp: pawnHp,
                  maxHp: pawnMaxHp,
                  spriteSize: actorSize,
                ),
              );
            }

            final enemyActors = enemies.map((enemy) {
              final size =
                  actorSize +
                  (enemy.boss
                      ? 22
                      : enemy.elite
                      ? 10
                      : 0);
              return battleActor(
                label: widget.linguaInglese ? enemy.nameEn : enemy.nameIt,
                color: elementColor(enemy.elementId),
                kind: spriteKindForElement(enemy.elementId, enemy.nameIt),
                seed: stableSpriteSeed(
                  'enemy:${enemy.monsterId ?? enemy.nameIt}:${enemy.elementId}:${enemy.level}:${enemy.grade}',
                ),
                faceRight: enemySpriteFacesRight(enemy),
                layers: enemy.boss
                    ? 4
                    : enemy.elite
                    ? 2
                    : 1,
                hp: enemy.hp,
                maxHp: enemy.maxHp,
                spriteSize: size,
                assetPath: monsterDungeonSpriteAsset(
                  enemy.elementId,
                  enemy.nameIt,
                  enemy.spriteAssetPath,
                ),
              );
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.view_agenda, color: c, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('Vista classica', 'Classic view'),
                        style: TextStyle(
                          color: c,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      t('party <- -> nemici', 'party <- -> enemies'),
                      style: const TextStyle(
                        color: Color(0xFFBFB7DD),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: stageHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF080912),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.withValues(alpha: 0.28)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF080912),
                                const Color(0xFF090A13),
                                c.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < 5; i++)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 18.0 + i * 18.0,
                          child: Container(
                            height: 1,
                            color: const Color(
                              0xFFFFD36A,
                            ).withValues(alpha: 0.12),
                          ),
                        ),
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 12, 6, 6),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    alignment: WrapAlignment.start,
                                    crossAxisAlignment: WrapCrossAlignment.end,
                                    children: partyActors,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 14),
                              color: c.withValues(alpha: 0.16),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(6, 12, 8, 6),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment: WrapCrossAlignment.end,
                                    children: enemyActors,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return compactCard(
      borderColor: c,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(Icons.sports_martial_arts, color: c, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t(
                      'Abisso dell’Occhio • Piano $currentFloor',
                      'Eye Abyss • Floor $currentFloor',
                    ),
                    style: TextStyle(color: c, fontWeight: FontWeight.w900),
                  ),
                ),
                if (showTopQuickIcons)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (canUseCombatInput)
                        stageQuickButton(
                          label: 'VC',
                          icon: Icons.flash_on,
                          color: Colors.amber,
                          onPressed: () => attack(useVc: true),
                        ),
                      if (canUseCombatInput && canUseCmAttack())
                        stageQuickButton(
                          label: 'CM',
                          icon: Icons.blur_on,
                          color: const Color(0xFFA78BFA),
                          onPressed: () => attack(useVc: false),
                        ),
                      if (canUseCombatInput && canUseAoeVc())
                        stageQuickButton(
                          label: 'AoE',
                          icon: Icons.trip_origin,
                          color: Colors.orangeAccent,
                          onPressed: () => attackAllEnemies(useVc: true),
                        ),
                      if (canUseCombatInput && reactionAvailable)
                        stageQuickButton(
                          label: t('Difesa', 'Defense'),
                          icon: Icons.shield,
                          color: Colors.greenAccent,
                          onPressed: useReactionDefense,
                        ),
                      if (canUseCombatInput &&
                          (activeArt != null || selectedRunArtIds.isNotEmpty))
                        stageQuickButton(
                          label: 'Art',
                          icon: Icons.auto_fix_high,
                          color: const Color(0xFFA78BFA),
                          onPressed: showArtShortcutChoices,
                        ),
                      stageQuickButton(
                        label: t('Info', 'Info'),
                        icon: Icons.info_outline,
                        color: Colors.lightBlueAccent,
                        onPressed: showInfoShortcutChoices,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaSize = MediaQuery.of(context).size;
              final phoneLandscape =
                  mediaSize.shortestSide < 600 &&
                  mediaSize.width > mediaSize.height;
              final narrow = constraints.maxWidth < 430;
              final wide = constraints.maxWidth >= 900;
              final stageHeight = phoneLandscape
                  ? 390.0
                  : narrow
                  ? 500.0
                  : wide
                  ? 430.0
                  : 300.0;
              final enemyWidgets = enemies.map((enemy) {
                return battleActor(
                  label: widget.linguaInglese ? enemy.nameEn : enemy.nameIt,
                  color: elementColor(enemy.elementId),
                  kind: spriteKindForElement(enemy.elementId, enemy.nameIt),
                  seed: stableSpriteSeed(
                    'enemy:${enemy.monsterId ?? enemy.nameIt}:${enemy.elementId}:${enemy.level}:${enemy.grade}',
                  ),
                  faceRight: enemySpriteFacesRight(enemy),
                  layers: enemy.elite
                      ? 2
                      : enemy.boss
                      ? 4
                      : 1,
                  hp: enemy.hp,
                  maxHp: enemy.maxHp,
                  spriteSize: phoneLandscape
                      ? enemy.boss
                            ? 132
                            : enemy.elite
                            ? 110
                            : 96
                      : enemy.boss
                      ? 104
                      : enemy.elite
                      ? 88
                      : 74,
                  assetPath: monsterDungeonSpriteAsset(
                    enemy.elementId,
                    enemy.nameIt,
                    enemy.spriteAssetPath,
                  ),
                );
              }).toList();
              final enemyAlignment = WrapAlignment.end;
              final infoPanelVisible =
                  wide && enemies.isNotEmpty && showInfoEnemyPanel;
              final enemyAreaLeft = narrow
                  ? constraints.maxWidth * (enemies.length > 1 ? 0.44 : 0.54)
                  : wide
                  ? constraints.maxWidth * 0.50
                  : phoneLandscape
                  ? constraints.maxWidth * 0.48
                  : constraints.maxWidth * 0.42;
              final enemyAreaRight = infoPanelVisible
                  ? 238.0
                  : narrow
                  ? 10.0
                  : wide
                  ? 24.0
                  : phoneLandscape
                  ? 24.0
                  : 18.0;
              final playerBottom = narrow
                  ? 232.0
                  : wide
                  ? 214.0
                  : phoneLandscape
                  ? 76.0
                  : 42.0;
              final allyAreaWidth = narrow
                  ? constraints.maxWidth * 0.68
                  : wide
                  ? min(520.0, max(392.0, constraints.maxWidth * 0.43))
                  : phoneLandscape
                  ? 280.0
                  : 220.0;
              final allySpacing = wide ? 8.0 : 4.0;
              final allyRunSpacing = wide ? 8.0 : 2.0;
              final allyScale = narrow ? 0.84 : 1.0;
              final stageCacheWidth = rasterCacheDimension(
                constraints.maxWidth,
                max: 1920,
              );
              final stageCacheHeight = rasterCacheDimension(
                stageHeight,
                max: 1080,
              );

              return Container(
                width: double.infinity,
                height: stageHeight,
                margin: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF090A13),
                  borderRadius: BorderRadius.circular(wide ? 18 : 12),
                  border: Border.all(color: c.withValues(alpha: 0.34)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/oculum/sfondo.png',
                        fit: BoxFit.cover,
                        cacheWidth: stageCacheWidth,
                        cacheHeight: stageCacheHeight,
                        errorBuilder: (context, error, stackTrace) =>
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF090A13),
                              ),
                            ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.44),
                        ),
                      ),
                    ),
                    if (wide)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Opacity(
                            opacity: 0.92,
                            child: _OculumDungeonSkinSystem(this)
                                .buildOculumAssetIcon(
                                  size: 66,
                                  dotted: enemyElementId == 'nullum',
                                ),
                          ),
                        ),
                      ),
                    if (wide)
                      Positioned(
                        left: 16,
                        top: 14,
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_bottom, color: c, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              t(
                                "Turno ${enemyTurnPending ? 'mostri' : 'tu'}",
                                "Turn ${enemyTurnPending ? 'monsters' : 'you'}",
                              ),
                              style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      left: narrow
                          ? 14
                          : wide
                          ? 22
                          : phoneLandscape
                          ? 24
                          : 18,
                      bottom: playerBottom,
                      child: battleActor(
                        label: safeSpriteLabel(
                          playerNameInRun,
                          t('Personaggio', 'Character'),
                        ),
                        color: playerAppearanceColor,
                        kind: currentPlayerSpriteKind,
                        seed: stableSpriteSeed(
                          'player:${safeSpriteLabel(playerNameInRun, 'character')}',
                        ),
                        faceRight: true,
                        layers: playerAppearanceLayers,
                        hp: playerHp,
                        maxHp: playerMaxHp,
                        spriteSize: narrow
                            ? 72
                            : wide
                            ? 122
                            : phoneLandscape
                            ? 116
                            : 96,
                        eyeColor: playerEyeColor,
                        weaponKind: currentPlayerSkinHidesEquipment
                            ? ''
                            : playerWeaponSpriteKind,
                        weaponColor: playerWeaponColor,
                        weaponSeed: playerWeaponSeed,
                        armorKind: currentPlayerSkinHidesEquipment
                            ? ''
                            : playerArmorSpriteKind,
                        armorColor: playerArmorColor,
                        armorSeed: playerArmorSeed,
                        assetPath: playerDungeonSpriteAssetForKind(
                          currentPlayerSpriteKind,
                        ),
                        armorAssetPath: dungeonArmorAssetForKind(
                          playerArmorSpriteKind,
                        ),
                      ),
                    ),
                    Positioned(
                      left: narrow
                          ? 10
                          : wide
                          ? 24
                          : phoneLandscape
                          ? 24
                          : 18,
                      bottom: narrow
                          ? 10
                          : wide
                          ? 24
                          : phoneLandscape
                          ? 24
                          : 18,
                      child: SizedBox(
                        width: allyAreaWidth,
                        child: Transform.scale(
                          scale: allyScale,
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            width: allyAreaWidth / allyScale,
                            child: Wrap(
                              spacing: allySpacing,
                              runSpacing: allyRunSpacing,
                              alignment: WrapAlignment.start,
                              children: allyActors,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: enemyAreaLeft,
                      right: enemyAreaRight,
                      top: narrow
                          ? 64
                          : wide
                          ? 108
                          : phoneLandscape
                          ? 58
                          : 34,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: enemyAlignment,
                        children: enemyWidgets,
                      ),
                    ),
                    if (wide && enemies.isNotEmpty && showInfoEnemyPanel)
                      Positioned(
                        right: 18,
                        top: 58,
                        width: 200,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xD8080910),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: c.withValues(alpha: 0.34),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('INFO NEMICO', 'ENEMY INFO'),
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: dungeonSpriteArt(
                                    color: elementColor(
                                      enemies.first.elementId,
                                    ),
                                    seed: stableSpriteSeed(
                                      'enemy-info:${enemies.first.monsterId ?? enemies.first.nameIt}',
                                    ),
                                    kind: spriteKindForElement(
                                      enemies.first.elementId,
                                      enemies.first.nameIt,
                                    ),
                                    eyeColor: Colors.white,
                                    layers: enemies.first.boss
                                        ? 4
                                        : enemies.first.elite
                                        ? 2
                                        : 1,
                                    flip: !enemySpriteFacesRight(enemies.first),
                                    assetPath: monsterDungeonSpriteAsset(
                                      enemies.first.elementId,
                                      enemies.first.nameIt,
                                      enemies.first.spriteAssetPath,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.linguaInglese
                                    ? enemies.first.nameEn
                                    : enemies.first.nameIt,
                                style: TextStyle(
                                  color: elementColor(enemies.first.elementId),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                enemies.first.elementId == 'nullum'
                                    ? 'Null/Fateless: mini-boss molto forte.\nImmune a Fato.\nColpisce verità che ignorano il destino.'
                                    : '${t('Classe', 'Class')}: ${enemies.first.boss
                                          ? 'Boss'
                                          : enemies.first.elite
                                          ? 'Mini-Boss'
                                          : 'Normale'}\nHP ${enemies.first.hp}/${enemies.first.maxHp}\nATK ${enemies.first.attack} • DEF ${enemies.first.defense}',
                                style: TextStyle(
                                  color: Colors.grey.shade200,
                                  height: 1.28,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                statChip(
                  t('Alleati', 'Allies'),
                  '${allyActors.length}',
                  color: Colors.tealAccent,
                ),
                statChip(
                  t('Nemici', 'Enemies'),
                  '${enemies.length}',
                  color: enemies.isEmpty ? c : elementColor(enemyElementId),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: toggleCombatHudDetails,
                  child: statChip(
                    t('Dettagli', 'Details'),
                    showCombatHudDetails ? 'ON' : 'OFF',
                    color: const Color(0xFFA78BFA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSpriteCodexPanel(Color c) {
    if (!showSpriteCodex) return const SizedBox.shrink();

    final cards = <Widget>[
      spriteBox(
        label: safeSpriteLabel(playerNameInRun, t('Personaggio', 'Character')),
        color: playerAppearanceColor,
        kind: currentPlayerSpriteKind,
        seed: stableSpriteSeed(
          'player:${safeSpriteLabel(playerNameInRun, 'character')}',
        ),
        layers: playerAppearanceLayers,
        eyeColor: playerEyeColor,
        weaponKind: currentPlayerSkinHidesEquipment
            ? ''
            : playerWeaponSpriteKind,
        weaponColor: playerWeaponColor,
        weaponSeed: playerWeaponSeed,
        armorKind: currentPlayerSkinHidesEquipment ? '' : playerArmorSpriteKind,
        armorColor: playerArmorColor,
        armorSeed: playerArmorSeed,
        assetPath: playerDungeonSpriteAssetForKind(currentPlayerSpriteKind),
        armorAssetPath: dungeonArmorAssetForKind(playerArmorSpriteKind),
      ),
    ];

    if (starterWeapon != null) {
      cards.add(
        spriteBox(
          label:
              '${t('Arma', 'Weapon')}\n${widget.linguaInglese ? starterWeapon!.nameEn : starterWeapon!.nameIt}',
          color: elementColor(starterWeapon!.elementId),
          kind: itemSpriteKind(
            'weapon',
            starterWeapon!.elementId,
            starterWeapon!.nameIt,
          ),
          seed: stableSpriteSeed('weapon:${starterWeapon!.id}'),
          layers: 1,
          size: 64,
        ),
      );
    }

    if (activeCostume != null) {
      cards.add(
        spriteBox(
          label:
              '${t('Armatura', 'Armor')}\n${widget.linguaInglese ? activeCostume!.nameEn : activeCostume!.nameIt}',
          color: elementColor(activeCostume!.elementId),
          kind: itemSpriteKind(
            'costume',
            activeCostume!.elementId,
            activeCostume!.nameIt,
          ),
          seed: stableSpriteSeed('costume:${activeCostume!.id}'),
          layers: 2,
          size: 64,
          assetPath: dungeonArmorAssetForKind(activeCostume!.id),
        ),
      );
    }

    if (activeArt != null) {
      cards.add(
        spriteBox(
          label:
              'Art\n${widget.linguaInglese ? activeArt!.nameEn : activeArt!.nameIt}',
          color: elementColor(activeArt!.elementId),
          kind: itemSpriteKind('art', activeArt!.elementId, activeArt!.nameIt),
          seed: stableSpriteSeed('art:${activeArt!.effectId}'),
          layers: skillLevel(activeArt!.effectId).clamp(1, 4).toInt(),
          size: 64,
        ),
      );
    }

    if (activeRelic != null) {
      cards.add(
        spriteBox(
          label:
              '${t('Reliquia', 'Relic')}\n${widget.linguaInglese ? activeRelic!.nameEn : activeRelic!.nameIt}',
          color: const Color(0xFFA78BFA),
          kind: activeRelic!.effectId == 'pawn_guardian'
              ? 'pawn'
              : itemSpriteKind('relic', 'oculum', activeRelic!.nameIt),
          seed: stableSpriteSeed('relic:${activeRelic!.id}'),
          layers: 3,
          size: 64,
          eyeColor: activeRelic!.effectId == 'pawn_guardian'
              ? widget.tertiaryColor
              : Colors.white,
          assetPath: activeRelic!.effectId == 'oculum_shield_converter'
              ? 'assets/oculum_dungeon/generated_sprites/equipment/oculum_shield_relic.png'
              : null,
        ),
      );
    }

    for (final drop in attachedDrops.take(6)) {
      cards.add(
        spriteBox(
          label:
              '${t('Drop', 'Drop')}\n${widget.linguaInglese ? drop.nameEn : drop.nameIt}',
          color: elementColor(drop.elementId),
          kind: itemSpriteKind('drop', drop.elementId, drop.nameIt),
          seed: stableSpriteSeed('attached:${drop.dropId}'),
          layers: 2,
          size: 60,
        ),
      );
    }

    for (final ally in activeAllies.take(8)) {
      cards.add(
        spriteBox(
          label:
              '${t('Alleato', 'Ally')}\n${widget.linguaInglese ? ally.nameEn : ally.nameIt}',
          color: elementColor(ally.elementId),
          kind: spriteKindForElement(ally.elementId, ally.nameIt),
          seed: stableSpriteSeed('ally:${ally.id}'),
          layers: allySpriteLayers(ally),
          size: 60,
          flip: !allySpriteFacesRight(ally),
          assetPath: monsterDungeonSpriteAsset(ally.elementId, ally.nameIt),
        ),
      );
    }

    if (pawnHp > 0) {
      cards.add(
        spriteBox(
          label: t('Pedina\nPawn', 'Chess piece\nPawn'),
          color: widget.tertiaryColor,
          kind: 'pawn',
          seed: stableSpriteSeed('ally:pawn'),
          layers: 2,
          size: 60,
          eyeColor: widget.tertiaryColor,
        ),
      );
    }

    return compactCard(
      borderColor: const Color(0xFFA78BFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view, color: Color(0xFFA78BFA), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Pagina sprite singoli', 'Single sprite page'),
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: t('Chiudi', 'Close'),
                onPressed: () => setState(() => showSpriteCodex = false),
                icon: const Icon(Icons.close, color: Color(0xFFA78BFA)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 14, children: cards),
        ],
      ),
    );
  }

  Widget buildTrapMiniGamePanel(Color c) {
    if (!trapMiniGameActive) return const SizedBox.shrink();
    final hazards = trapHazardsForStep(trapStep);
    final revealedSafeLane = trapRevealedStep == trapStep
        ? trapSafeLaneForStep(trapStep)
        : -1;
    return compactCard(
      borderColor: Colors.redAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Minigioco trappola', 'Trap minigame'),
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (lane) {
              final hazard = hazards.contains(lane);
              final player = trapPlayerLane == lane;
              final safe = revealedSafeLane == lane;
              return Expanded(
                child: Container(
                  height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: safe
                        ? Colors.tealAccent.withValues(alpha: .16)
                        : hazard
                        ? Colors.redAccent.withValues(alpha: .20)
                        : const Color(0xFF11121E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: player
                          ? Colors.tealAccent
                          : safe
                          ? Colors.tealAccent
                          : hazard
                          ? Colors.redAccent
                          : const Color(0xFF3A3558),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      player
                          ? 'YOU'
                          : safe
                          ? 'SAFE'
                          : hazard
                          ? 'EYE'
                          : '',
                      style: TextStyle(
                        color: player || safe
                            ? Colors.tealAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              modernActionButton(
                label: t('Sinistra', 'Left'),
                icon: Icons.arrow_left,
                color: Colors.tealAccent,
                onPressed: () => trapMiniGameMove(-1),
              ),
              modernActionButton(
                label: t('Fermo', 'Stay'),
                icon: Icons.radio_button_checked,
                color: widget.tertiaryColor,
                onPressed: () => trapMiniGameMove(0),
              ),
              modernActionButton(
                label: t('Destra', 'Right'),
                icon: Icons.arrow_right,
                color: Colors.tealAccent,
                onPressed: () => trapMiniGameMove(1),
              ),
              modernActionButton(
                label: t(
                  'Leggi ($trapFocusCharges)',
                  'Read ($trapFocusCharges)',
                ),
                icon: Icons.visibility,
                color: const Color(0xFF8B5CF6),
                onPressed: trapFocusCharges > 0 ? trapMiniGameReveal : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Step ${trapStep + 1}/$trapStepsTotal - Hit $trapHits - Combo $trapCurrentCombo',
            style: const TextStyle(
              color: Color(0xFFBFB7DD),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTopStatus(Color c) {
    return compactCard(
      borderColor: c,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: c, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('Dungeon di Oculum', 'Oculum Dungeon'),
                  style: TextStyle(
                    color: c,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              _OculumDungeonSkinSystem(this).buildQuickSettingsButton(),
              IconButton(
                tooltip: t('Chiudi', 'Close'),
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: widget.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              statChip(
                t('Piano', 'Floor'),
                '$currentFloor/$maxFloors',
                color: c,
              ),
              statChip(
                t('Fase', 'Phase'),
                widget.linguaInglese
                    ? cyclePhase().nameEn
                    : cyclePhase().nameIt,
                color: const Color(0xFFA78BFA),
              ),
              statChip(t('Stanza', 'Room'), '$room/$maxRooms', color: c),
              statChip('EXP', '$dungeonExp/$expToNextDungeonLevel', color: c),
              statChip('Oculum', '$oculumCharges/$oculumMaxCharges'),
              statChip(
                'Karma',
                dungeonKarma >= 0 ? '+$dungeonKarma' : '$dungeonKarma',
                color: dungeonKarma > 0
                    ? Colors.lightGreenAccent
                    : dungeonKarma < 0
                    ? Colors.redAccent
                    : const Color(0xFFB9A9FF),
              ),
              if (playerOculumShieldMax > 0)
                statChip(
                  'SO',
                  '$playerOculumShield/$playerOculumShieldMax',
                  color: widget.tertiaryColor,
                ),
              if (showCombatHudDetails) ...[
                statChip(
                  'Obser',
                  '$obserInRun',
                  leading: obserSpriteIcon(size: 14),
                ),
                statChip('Dust', '$ascensionDustInRun'),
                if (posteaRunicMetalKg > 0)
                  statChip('Metallo', posteaRunicMetalLabel),
                statChip(
                  'Spento',
                  '$oculumSpento',
                  color: const Color(0xFF8B5CF6),
                ),
                statChip(t('Danno', 'Damage'), '$totalDamage'),
                statChip(t('Difesa', 'Defense'), '$totalDefense'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void toggleCombatHudDetails() {
    setState(() => showCombatHudDetails = !showCombatHudDetails);
  }

  Widget buildMainBars(Color c) {
    if (inCombat && showSpritePanel && !classicCombatView) {
      return compactCard(
        borderColor: c,
        child: Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            statChip('HP', '$playerHp/$playerMaxHp', color: c),
            if (playerShield > 0)
              statChip(
                'Shield',
                '$playerShield',
                color: Colors.lightBlueAccent,
              ),
            if (playerOculumShieldMax > 0)
              statChip(
                'SO',
                '$playerOculumShield/$playerOculumShieldMax',
                color: widget.tertiaryColor,
              ),
            statChip(
              'Karma',
              dungeonKarma >= 0 ? '+$dungeonKarma' : '$dungeonKarma',
              color: dungeonKarma > 0
                  ? Colors.lightGreenAccent
                  : dungeonKarma < 0
                  ? Colors.redAccent
                  : const Color(0xFFB9A9FF),
            ),
            statChip('Oculum', '$oculumCharges/$oculumMaxCharges'),
          ],
        ),
      );
    }

    return compactCard(
      borderColor: c,
      child: Column(
        children: [
          bar(
            label:
                '$playerNameInRun • Shield $playerShield${playerOculumShieldMax > 0 ? ' • SO $playerOculumShield/$playerOculumShieldMax' : ''} • Karma ${dungeonKarma >= 0 ? '+$dungeonKarma' : dungeonKarma}',
            current: playerHp,
            maxValue: playerMaxHp,
            color: c,
          ),
          if (inCombat) ...[
            const SizedBox(height: 12),
            bar(
              label:
                  '${widget.linguaInglese ? enemyNameEn : enemyNameIt} • ${elementName(enemyElementId)}',
              current: enemyHp,
              maxValue: enemyMaxHp,
              color: elementColor(enemyElementId),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildStoryBox(Color c) {
    return compactCard(
      borderColor: c,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120, maxHeight: 235),
        child: SingleChildScrollView(
          child: Text(
            cleanDungeonText(widget.linguaInglese ? textEn : textIt),
            style: const TextStyle(
              color: Color(0xFFE8E2FF),
              fontSize: 14,
              height: 1.38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEventChoicesPanel() {
    if (eventChoices.isEmpty) return const SizedBox.shrink();

    return collapsiblePanel(
      title: t(choicePanelTitleIt(), choicePanelTitleEn()),
      icon: choicePanelIcon(),
      expanded: showEventChoices,
      trailing: '${eventChoices.length}',
      color: choicePanelColor(),
      onTap: () => setState(() => showEventChoices = !showEventChoices),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: eventChoices
            .map(
              (choice) => modernActionButton(
                label: widget.linguaInglese ? choice.labelEn : choice.labelIt,
                icon: choice.icon,
                color: choice.color ?? widget.tertiaryColor,
                onPressed: choice.onPressed,
              ),
            )
            .toList(),
      ),
    );
  }

  VoidCallback unavailableShortcut() {
    return () {
      setState(() {
        textIt = 'Azione non disponibile in questo momento.';
        textEn = 'Action not available right now.';
      });
    };
  }

  void showAttackShortcutChoices() {
    setState(() {
      clearChoices(mode: 'attack');
      textIt = 'Attacco.\nScegli il colpo come in un menu fight compatto.';
      textEn = 'Attack.\nPick the move from a compact fight menu.';
      eventChoices.addAll([
        _DungeonChoice(
          labelIt: 'Attacca VC',
          labelEn: 'VC Attack',
          icon: Icons.flash_on,
          color: Colors.amber,
          onPressed: runActive && canUseCombatInput
              ? () => attack(useVc: true)
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Attacca CM',
          labelEn: 'CM Attack',
          icon: Icons.hardware,
          color: widget.primaryColor,
          onPressed: runActive && canUseCombatInput && canUseCmAttack()
              ? () => attack(useVc: false)
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'AoE VC',
          labelEn: 'AoE VC',
          icon: Icons.blur_circular,
          color: Colors.deepOrangeAccent,
          onPressed: runActive && canUseCombatInput && canUseAoeVc()
              ? () => attackAllEnemies(useVc: true)
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'AoE CM',
          labelEn: 'AoE CM',
          icon: Icons.bubble_chart,
          color: Colors.lightBlueAccent,
          onPressed: runActive && canUseCombatInput && canUseAoeCm()
              ? () => attackAllEnemies(useVc: false)
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Tecnica Art',
          labelEn: 'Art Tech',
          icon: Icons.blur_on,
          color: const Color(0xFFFFD36A),
          onPressed: canUseArtTechnique()
              ? useArtTechnique
              : unavailableShortcut(),
        ),
      ]);
    });
  }

  void showDefenseShortcutChoices() {
    setState(() {
      clearChoices(mode: 'defense');
      textIt = 'Difesa.\nDifenditi, contrattacca o fuggi.';
      textEn = 'Defense.\nDefend, counter, or flee.';
      eventChoices.addAll([
        _DungeonChoice(
          labelIt: 'Difenditi',
          labelEn: 'Defend',
          icon: Icons.shield,
          color: Colors.greenAccent,
          onPressed: runActive && canUseCombatInput && reactionAvailable
              ? useReactionDefense
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Counter',
          labelEn: 'Counter',
          icon: Icons.sync,
          color: const Color(0xFFE11D48),
          onPressed: runActive && canUseCombatInput && reactionAvailable
              ? useReactionCounter
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Fuggi',
          labelEn: 'Flee',
          icon: Icons.directions_run,
          color: Colors.redAccent,
          onPressed: runActive && canUseCombatInput
              ? fleeCombat
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Riposo',
          labelEn: 'Rest',
          icon: Icons.nightlight,
          color: const Color(0xFFC4B5FD),
          onPressed:
              runActive && !inCombat && !gameOver && !restActionUsedThisRoom
              ? restShort
              : unavailableShortcut(),
        ),
      ]);
    });
  }

  void showArtShortcutChoices() {
    setState(() {
      clearChoices(mode: 'art');
      showCombatActions = true;
      final maxArtText = t(
        hasOculianPact
            ? 'Slot Art: patto Oculiano attivo, massimo 3 con almeno 2 Oculum.'
            : 'Slot Art: massimo 2. Gli Oculiani arrivano a 3 con almeno 2 Oculum.',
        hasOculianPact
            ? 'Art slots: Oculian pact active, max 3 with at least 2 Oculum.'
            : 'Art slots: max 2. Oculians reach 3 with at least 2 Oculum.',
      );
      textIt = 'Azioni Art e Oculum.\n$maxArtText';
      textEn = 'Art and Oculum actions.\n$maxArtText';
      eventChoices.addAll([
        _DungeonChoice(
          labelIt: 'Skill Oculum',
          labelEn: 'Oculum Skill',
          icon: Icons.auto_fix_high,
          color: const Color(0xFF8B5CF6),
          onPressed: activeArt != null && runActive && !gameOver
              ? showArtSkillChoices
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Cambia Art run',
          labelEn: 'Change run Art',
          icon: Icons.swap_horiz,
          color: elementColor(activeElementId),
          onPressed: runActive && !gameOver
              ? showRunArtSwapChoices
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Apri Art Board',
          labelEn: 'Open Art Board',
          icon: Icons.dashboard_customize,
          color: const Color(0xFFFFD36A),
          onPressed: () {
            setState(() {
              showArtBoard = true;
              textIt = 'Art Board aperta. Puoi controllare e cambiare le Art.';
              textEn = 'Art Board opened. You can inspect and change Arts.';
            });
          },
        ),
      ]);
    });
  }

  void showRelicShortcutChoices() {
    setState(() {
      clearChoices(mode: 'relic');
      showCombatActions = true;
      final relicName = activeRelic == null
          ? t('Nessuna reliquia', 'No relic')
          : widget.linguaInglese
          ? activeRelic!.nameEn
          : activeRelic!.nameIt;
      textIt =
          'Azioni Reliquia.\n$relicName\n\nSkill Reliquia: uso più leggero. Open Reliquia: potere pieno con ricarica.';
      textEn =
          'Relic actions.\n$relicName\n\nRelic Skill: lighter use. Relic Open: full power with cooldown.';
      eventChoices.addAll([
        _DungeonChoice(
          labelIt: 'Skill Reliquia',
          labelEn: 'Relic Skill',
          icon: Icons.blur_on,
          color: const Color(0xFFA78BFA),
          onPressed: useRelicSkill,
        ),
        _DungeonChoice(
          labelIt: 'Open Reliquia',
          labelEn: 'Relic Open',
          icon: Icons.stars,
          color: const Color(0xFFFF5A3C),
          onPressed: useRelicOpen,
        ),
      ]);
    });
  }

  void showInfoShortcutChoices() {
    setState(() {
      clearChoices(mode: 'info');
      textIt = 'Achievement e informazioni.\nGestisci sblocchi, party e vista.';
      textEn = 'Achievements and information.\nManage unlocks, party and view.';
      eventChoices.addAll([
        _DungeonChoice(
          labelIt: 'Achievement',
          labelEn: 'Achievements',
          icon: Icons.emoji_events,
          color: Colors.amber,
          onPressed: showAchievementChoices,
        ),
        _DungeonChoice(
          labelIt: 'Alleati',
          labelEn: 'Allies',
          icon: Icons.groups,
          color: Colors.tealAccent,
          onPressed: showAllyChoices,
        ),
        _DungeonChoice(
          labelIt: 'Cambia arma run',
          labelEn: 'Change run weapon',
          icon: Icons.flash_on,
          color: const Color(0xFFFFD36A),
          onPressed: runActive
              ? showRunWeaponSwapChoices
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Cambia Art run',
          labelEn: 'Change run Art',
          icon: Icons.auto_fix_high,
          color: const Color(0xFFA78BFA),
          onPressed: runActive ? showRunArtSwapChoices : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Gestisci party run',
          labelEn: 'Manage run party',
          icon: Icons.swap_horiz,
          color: Colors.tealAccent,
          onPressed: runActive
              ? showRunPartyManageChoices
              : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Aspetto e skin',
          labelEn: 'Look and skins',
          icon: Icons.brush,
          color: widget.tertiaryColor,
          onPressed: showAppearanceEditor,
        ),
        _DungeonChoice(
          labelIt: showSpriteCodex ? 'Chiudi sprite' : 'Pagina sprite',
          labelEn: showSpriteCodex ? 'Close sprites' : 'Sprite page',
          icon: Icons.grid_view,
          color: const Color(0xFFA78BFA),
          onPressed: () => setState(() => showSpriteCodex = !showSpriteCodex),
        ),
        _DungeonChoice(
          labelIt: 'Titoli Run',
          labelEn: 'Run Titles',
          icon: Icons.workspace_premium,
          color: const Color(0xFFFFD36A),
          onPressed: runActive ? showTitleChoices : unavailableShortcut(),
        ),
        _DungeonChoice(
          labelIt: 'Sblocchi',
          labelEn: 'Unlocks',
          icon: Icons.lock_open,
          color: const Color(0xFF8B5CF6),
          onPressed: showUnlockHub,
        ),
        if (hasValleyInTeam && !valleyTrainingUsedThisRun && !inCombat)
          _DungeonChoice(
            labelIt: 'Allenamento',
            labelEn: 'Training',
            icon: Icons.fitness_center,
            color: const Color(0xFF55B86B),
            onPressed: offerValleyTrainingEvent,
          ),
        _DungeonChoice(
          labelIt: 'Manuale Oculum',
          labelEn: 'Oculum Manual',
          icon: Icons.menu_book,
          color: Colors.lightBlueAccent,
          onPressed: showDungeonManual,
        ),
      ]);
    });
  }

  void showRunWeaponSwapChoices() {
    setState(() {
      clearChoices(mode: 'info');
      textIt =
          'Armi trovate/sbloccate in questa run.\nScegli quale equipaggiare ora.';
      textEn =
          'Weapons found/unlocked in this run.\nChoose which one to equip now.';
      for (final weapon in availableStartingWeapons()) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: weapon.nameIt,
            labelEn: weapon.nameEn,
            icon: Icons.flash_on,
            color: elementColor(weapon.elementId),
            onPressed: () {
              setState(() {
                starterWeapon = weapon;
                textIt = 'Arma equipaggiata: ${weapon.nameIt}.';
                textEn = 'Equipped weapon: ${weapon.nameEn}.';
                saveRunCheckpoint(
                  reasonIt: 'Arma run cambiata.',
                  reasonEn: 'Run weapon changed.',
                );
              });
            },
          ),
        );
      }
    });
  }

  void showRunArtSwapChoices() {
    setState(() {
      clearChoices(mode: 'art');
      final artIds = selectedRunArtIds.isEmpty
          ? activeArt != null
                ? <String>{activeArt!.effectId}
                : availableStartingArts().map((a) => a.effectId).toSet()
          : selectedRunArtIds;
      textIt = 'Art disponibili in run: ${artIds.length}.';
      textEn = 'Available run Arts: ${artIds.length}.';
      for (final art in _allArts.where((a) => artIds.contains(a.effectId))) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: art.nameIt,
            labelEn: art.nameEn,
            icon: Icons.auto_fix_high,
            color: elementColor(art.elementId),
            onPressed: () {
              setState(() {
                activeArt = art;
                textIt = 'Art attiva: ${art.nameIt}.';
                textEn = 'Active Art: ${art.nameEn}.';
                saveRunCheckpoint(
                  reasonIt: 'Art run cambiata.',
                  reasonEn: 'Run Art changed.',
                );
              });
            },
          ),
        );
      }
      if (eventChoices.isEmpty) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Apri Art Board',
            labelEn: 'Open Art Board',
            icon: Icons.dashboard_customize,
            color: const Color(0xFFFFD36A),
            onPressed: () => setState(() => showArtBoard = true),
          ),
        );
      }
    });
  }

  void showRunPartyManageChoices() {
    setState(() {
      clearChoices(mode: 'allies');
      textIt = 'Gestione party run.\nTocca per aggiungere/rimuovere alleati.';
      textEn = 'Run party management.\nTap to add/remove allies.';
      for (final npc in _goodNpcs.where(
        (n) =>
            unlockedNpcIds.contains(n.id) ||
            activeAllies.any((a) => a.id == n.id),
      )) {
        final active = activeAllies.any((a) => a.id == npc.id);
        eventChoices.add(
          _DungeonChoice(
            labelIt: '${active ? 'Rimuovi' : 'Aggiungi'}: ${npc.nameIt}',
            labelEn: '${active ? 'Remove' : 'Add'}: ${npc.nameEn}',
            icon: active ? Icons.person_remove : Icons.person_add,
            color: elementColor(npc.elementId),
            onPressed: () => toggleAlly(npc),
          ),
        );
      }
    });
  }

  void showValleyInfo() {
    setState(() {
      clearChoices(mode: 'info');
      textIt =
          'Valley.\n\n'
          'Valley e figlio di Madre Natura: corpo interamente verde, gonna di foglie, capelli verdi di media lunghezza e corona di foglie.\n'
          'Tre umani trasformati in piante umane seguono Valley: carne strappata, fiori visibili dentro il corpo, rami, foglie e cactus.\n\n'
          'Attacco: Valley concentra sfere trasparenti di natura e le scaglia contro i nemici. Nel 30% dei casi le sfere si dividono in quattro raggi.\n\n'
          'Sbocciatura: a fine fight Valley ha il 10% di trasformare i mostri in creature sbocciate. Contro i corrotti rossi la probabilità diventa 100%. Gli sbocciati possono sacrificarsi per proteggere Valley.\n\n'
          'Quando riesce, Valley sorride con un sorriso impossibilmente spalancato.';
      textEn =
          'Valley.\n\n'
          'Valley is a child of Mother Nature: fully green body, leaf skirt, medium green hair and leaf crown.\n'
          'Three humans transformed into plant-humans follow Valley: torn flesh, visible inner flowers, branches, leaves and cactus.\n\n'
          'Attack: Valley concentrates transparent nature spheres and throws them at enemies. In 30% of cases the spheres split into four rays.\n\n'
          'Blooming: at fight end Valley has a 10% chance to transform monsters into bloomed creatures. Against red corrupted enemies the chance becomes 100%. Bloomed creatures can sacrifice themselves to protect Valley.\n\n'
          'When it succeeds, Valley smiles with an impossibly wide smile.';
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Torna a Info',
          labelEn: 'Back to Info',
          icon: Icons.arrow_back,
          color: widget.tertiaryColor,
          onPressed: showInfoShortcutChoices,
        ),
      );
      if (hasValleyInTeam && !valleyTrainingUsedThisRun && !inCombat) {
        eventChoices.add(
          _DungeonChoice(
            labelIt: 'Allenamento con Valley',
            labelEn: 'Training with Valley',
            icon: Icons.fitness_center,
            color: const Color(0xFF55B86B),
            onPressed: offerValleyTrainingEvent,
          ),
        );
      }
    });
  }

  void showDungeonManual() {
    setState(() {
      clearChoices(mode: 'info');
      textIt =
          'Manuale rapido Oculum Dungeon.\n\n'
          'Turni: tu -> alleati -> mostri. Le azioni principali appaiono solo quando servono.\n'
          'DT = Difficoltà Tiro.\n'
          'CM = Classe Materia (soglia per colpirti).\n'
          'VC = Volontà Combattiva (bonus all attacco).\n'
          'Formula condivisa: +1 x Livello e +6 x Grado su DT, VC, CM, Danno, Difesa, Iniziativa e tiri statistica.\n'
          'Tiri statistica: Statistica / 2 + Livello + Grado x6. Iniziativa: Materia / 5 + Livello + Grado x6.\n'
          'Attacco: usa Volontà, arma, set e bonus. Difesa: (Volontà + Materia + Livello + Grado x6) / 2, poi scudo, armatura, reazioni e riduzioni.\n'
          'Oculum: ogni punto vale +2 potenza Art e alimenta Skill Oculum, Open e alcune reliquie. Le Art sono massimo 2, oppure 3 se sei Oculiano con due Oculum.\n'
          'Arma/Armatura/Scudo: contano nella probabilità di vittoria e negli sprite. Pawn e mostri-skin nascondono equip visivo ma mantengono i bonus.\n'
          'Skin: normali, umane, mostro e speciali. I mostri normali si sbloccano dopo 5 uccisioni, mini-boss dopo 3, boss dopo 1.\n'
          'Probabilità di vittoria: considera HP, alleati, nemici, danni, difesa, scudo, Oculum, skill, Open, status, set, pressione, boss e mini-boss.\n'
          'Mini-Boss/Boss: si adattano agli attacchi e ottengono resistenza; Mini-Boss x1.3 EXP, Boss x2 EXP.\n'
          'EXP: conta livello sopra il tuo x10, stats maggiori, grado superiore x1.2. Dopo 3 fight senza villaggio/taverna l EXP viene dimezzata a ogni fight extra.\n'
          'Null/Fateless: mini-boss puntinato e inquietante. Se ti ferisce e vinci: "ti senti ferito, non ricordi da cosa".\n'
          'Valley: appare al piano 3, resta per 1d20+6 turni, usa sfere natura, può allenarti senza morte reale e può far sbocciare i mostri a fine fight.';
      textEn =
          'Quick Oculum Dungeon manual.\n\n'
          'Turns: you -> allies -> monsters. Main actions appear only when useful.\n'
          'DT = Roll Difficulty.\n'
          'CM = Materia Class (threshold to hit you).\n'
          'VC = Combat Will (attack bonus).\n'
          'Shared formula: +1 x Level and +6 x Grade on DT, VC, CM, Damage, Defense, Initiative and stat rolls.\n'
          'Stat rolls: Stat / 2 + Level + Grade x6. Initiative: Materia / 5 + Level + Grade x6.\n'
          'Attack: uses Will, weapon, sets and bonuses. Defense: (Will + Materia + Level + Grade x6) / 2, then shield, armor, reactions and reductions.\n'
          'Oculum: each point gives +2 Art power and fuels Oculum Skills, Opens and some relics. Arts are max 2, or 3 if you are Oculian with two Oculum.\n'
          'Weapon/Armor/Shield: count for victory chance and sprites. Pawn and monster skins hide visual equipment while keeping bonuses.\n'
          'Skins: normal, human, monster and special. Normal monsters unlock after 5 kills, mini-bosses after 3, bosses after 1.\n'
          'Victory chance: considers HP, allies, enemies, damage, defense, shield, Oculum, skills, Opens, status, sets, pressure, bosses and mini-bosses.\n'
          'Mini-Boss/Boss: adapt to attacks and gain resistance; Mini-Boss x1.3 EXP, Boss x2 EXP.\n'
          'EXP: counts levels above you x10, higher stats, higher Grade x1.2. After 3 fights without village/tavern, EXP halves for every extra fight.\n'
          'Null/Fateless: dotted, disturbing mini-boss. If it wounds you and you win: "you feel wounded, but you do not remember by what".\n'
          'Valley: appears on floor 3, remains for 1d20+6 turns, uses nature spheres, can train you without real death and can make monsters bloom at fight end.';
      eventChoices.add(
        _DungeonChoice(
          labelIt: 'Torna a Info',
          labelEn: 'Back to Info',
          icon: Icons.arrow_back,
          color: widget.tertiaryColor,
          onPressed: showInfoShortcutChoices,
        ),
      );
    });
  }

  Widget buildCombatActionsPanel(BuildContext context, Color c) {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    final spacing = isMobile ? 6.0 : 8.0;
    final padding = EdgeInsets.all(isMobile ? 10 : 12);
    final compact = isMobile;

    // Azioni non richiudibile: deve restare sempre visibile.
    return compactCard(
      borderColor: c,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gamepad, color: c, size: compact ? 18 : 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Azioni', 'Actions'),
                  style: TextStyle(
                    color: c,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                t('contestuali', 'contextual'),
                style: TextStyle(
                  color: const Color(0xFFBFB7DD),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: [
              if (!runActive && !inCombat)
                modernActionButton(
                  label: t('Inizia', 'Start'),
                  icon: Icons.play_arrow,
                  color: widget.tertiaryColor,
                  onPressed: showStartRunWarning,
                  compact: compact,
                ),
              if (runActive && !inCombat && !gameOver)
                modernActionButton(
                  label: t('Esplora', 'Explore'),
                  icon: Icons.explore,
                  color: elementColor(activeElementId),
                  onPressed: exploreRoom,
                  compact: compact,
                ),
              if (runActive &&
                  !inCombat &&
                  !gameOver &&
                  !restActionUsedThisRoom)
                modernActionButton(
                  label: t('Riposo', 'Rest'),
                  icon: Icons.nightlight,
                  color: const Color(0xFFC4B5FD),
                  onPressed: restShort,
                  compact: compact,
                ),
              if (canUseCombatInput)
                modernActionButton(
                  label: t('Attacca', 'Attack'),
                  icon: Icons.flash_on,
                  color: Colors.amber,
                  onPressed: () => attack(useVc: true),
                  compact: compact,
                ),
              if (canUseCombatInput && reactionAvailable)
                modernActionButton(
                  label: t('Difenditi', 'Defend'),
                  icon: Icons.shield,
                  color: Colors.greenAccent,
                  onPressed: useReactionDefense,
                  compact: compact,
                ),
              if (canUseCombatInput &&
                  (activeArt != null ||
                      selectedRunArtIds.isNotEmpty ||
                      oculumCharges > 0))
                modernActionButton(
                  label:
                      'Art ${_OculumDungeonSkinSystem(this).maxArtSlotsLabel()}',
                  icon: Icons.auto_fix_high,
                  color: const Color(0xFFA78BFA),
                  onPressed: showArtShortcutChoices,
                  compact: compact,
                ),
              if (activeRelic != null && !gameOver)
                modernActionButton(
                  label: t('Reliquia', 'Relic'),
                  icon: Icons.blur_on,
                  color: const Color(0xFFA78BFA),
                  onPressed: showRelicShortcutChoices,
                  compact: compact,
                ),
              modernActionButton(
                label: t('Info', 'Info'),
                icon: Icons.emoji_events,
                color: Colors.lightBlueAccent,
                onPressed: showInfoShortcutChoices,
                compact: compact,
              ),
              modernActionButton(
                label: classicCombatView
                    ? t('Fight vivo', 'Live fight')
                    : t('Vista classica', 'Classic view'),
                icon: classicCombatView
                    ? Icons.sports_martial_arts
                    : Icons.view_agenda,
                color: const Color(0xFFA78BFA),
                onPressed: () =>
                    setState(() => classicCombatView = !classicCombatView),
                compact: compact,
              ),
              PopupMenuButton<String>(
                tooltip: t('Altro', 'More'),
                color: const Color(0xFF11121E),
                icon: Icon(Icons.more_horiz, color: c),
                onSelected: (value) {
                  if (value == 'bag') showQuickInventory();
                  if (value == 'art_board') {
                    setState(() => showArtBoard = !showArtBoard);
                  }
                  if (value == 'weapon_board') {
                    setState(() => showWeaponBoard = !showWeaponBoard);
                  }
                  if (value == 'delete') showDeleteSaveConfirm();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'bag', child: Text(t('Zaino', 'Bag'))),
                  PopupMenuItem(
                    value: 'art_board',
                    child: Text(t('Art Board', 'Art Board')),
                  ),
                  PopupMenuItem(
                    value: 'weapon_board',
                    child: Text(t('Board Armi', 'Weapon Board')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(t('Cancella Save', 'Delete Save')),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String buildRunSummaryText() {
    final weaponName = starterWeapon == null
        ? '—'
        : widget.linguaInglese
        ? starterWeapon!.nameEn
        : starterWeapon!.nameIt;
    final artName = activeArt == null
        ? '—'
        : widget.linguaInglese
        ? activeArt!.nameEn
        : activeArt!.nameIt;

    final armorName = activeCostume == null
        ? '—'
        : widget.linguaInglese
        ? activeCostume!.nameEn
        : activeCostume!.nameIt;

    final resistParts = elementalResist.entries
        .where((e) => e.value > 0)
        .map((e) => '${elementName(e.key)} +${e.value}')
        .take(12)
        .join(' • ');

    return '${t('Arma', 'Weapon')}: $weaponName\n'
        '${t('Armatura', 'Armor')}: $armorName\n'
        'Art: $artName\n'
        '${t('Probabilità vittoria', 'Win chance')}: ${estimatedVictoryChance()}%\n'
        'Reliquia: ${activeRelic == null
            ? '—'
            : widget.linguaInglese
            ? activeRelic!.nameEn
            : activeRelic!.nameIt}\n'
        'Difficoltà: $selectedDifficultyId • Tutorial: ${tutorialRunActive ? 'sì' : 'no'}\n'
        '${t('Elemento', 'Element')}: ${elementName(activeElementId)}\n'
        '${t('Scheda letta', 'Read sheet')}: ${widget.linguaInglese ? sheetBuildNameEn : sheetBuildNameIt} • Power $sheetPowerScore • ${proceduralDifficultyMultiplier.toStringAsFixed(2)}x\n'
        'OFF $sheetOffenseScore • DEF $sheetDefenseScore • OCU $sheetMagicScore\n'
        '${t('Piano', 'Floor')}: $currentFloor/$maxFloors • ${t('Stanze per piano', 'Rooms per floor')}: $roomsPerFloor\n'
        'Run Stats: Res +$dungeonResilienza • Vol +$dungeonVolonta • Mat +$dungeonMateria • Ocu +$dungeonOculum\n'
        '${t('Formula Lv/Grado', 'Level/Grade Formula')}: +$levelGradeCombatBonus (Lv ${widget.playerLevel} + Gr ${widget.playerGrade}x6) • VC $totalVc • CM $totalCm • ${t('Danno', 'Damage')} $totalDamage • ${t('Difesa', 'Defense')} $totalDefense • ${t('Iniziativa', 'Initiative')} $totalInitiative\n'
        '${buildArtSkillSummaryText()}\n'
        'Quest Skill: ${widget.linguaInglese ? activeSkillQuestEn : activeSkillQuestIt} [$activeSkillQuestProgress/$activeSkillQuestGoal]\n'
        '${t('Tecniche', 'Techniques')}: VC base • CM ${canUseCmAttack() ? 'ON' : 'LOCK'} • AoE VC ${canUseAoeVc() ? 'ON' : 'LOCK'} • AoE CM ${canUseAoeCm() ? 'ON' : 'LOCK'}\n'
        '${t('Riposo stanza', 'Room rest')}: ${restActionUsedThisRoom ? 'USATO' : 'OK'}\n'
        '${t('Sblocco tecniche', 'Technique unlock')}: CM skill 04/11 o item • AoE VC skill 08/12 o item • AoE CM skill 05/12 o item\n'
        '${t('Pergamene', 'Scrolls')}: $occultScrollsFound • Vault: $eliteVaultsCleared • Combo: $elementalComboHits\n'
        '${t('Zaino rapido', 'Quick bag')}: ${quickInventorySummary()}\n'
        '${t('Tecnica Art', 'Art Technique')}: ${artTechniqueCooldown <= 0 ? 'OK' : 'CD $artTechniqueCooldown'} • usi $artTechniqueUses\n'
        'Evonest proof $evonestProof • Affogato $drownedSummonTurns turni • Asher $asherContractUses\n'
        'Mille Fuochi: ${isInLastSixteenRooms ? 'FINALE' : 'chiusa'} • stanze restanti $roomsRemainingInRun\n'
        'LevelUpRest: ${levelUpRestAvailable ? 'pronto' : 'no'} • Rinascita: ${rebirthBlessingActive ? 'attiva' : 'no'} • ScudoCritico: ${criticalShieldActive ? 'attivo' : 'no'}\n'
        '${t('Drop incastonati', 'Socketed drops')}: ${attachedDrops.length}\n'
        '${t('Drop nello zaino', 'Drops in bag')}: ${inventoryDrops.length}\n'
        'Oculum: $oculumCharges/$oculumMaxCharges • Spento: $oculumSpento\n'
        '${t('Armi sbloccate', 'Unlocked weapons')}: ${unlockedWeaponIds.length}/${_starterWeapons.length}\n'
        '${t('Costumi sbloccati', 'Unlocked costumes')}: ${unlockedCostumeIds.length}/${_runCostumes.length}\n'
        '${t('Reforge', 'Reforge')}: $reforgeCount • ${t('Favore fabbro', 'Blacksmith favor')}: $blacksmithFavor\n'
        '${t('Resistenze', 'Resistances')}: ${resistParts.isEmpty ? '—' : resistParts}';
  }

  Widget quickStatPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF12131F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFEDE7FF),
              fontSize: 10.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget quickModernTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    double? progress,
    VoidCallback? onTap,
  }) {
    final p = progress?.clamp(0.0, 1.0).toDouble();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 146,
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.24),
              const Color(0xFF11121E),
              const Color(0xFF080914),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.13),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.36)),
                  ),
                  child: Icon(icon, color: color, size: 11),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF4F0FF),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9E94C4),
                  fontSize: 9.6,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
            if (p != null) ...[
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: p,
                  backgroundColor: const Color(0xFF1D1B2E),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget draggableQuickTile({
    required String id,
    required Widget child,
    required Color color,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != id,
      onAcceptWithDetails: (details) {
        setState(() {
          final from = quickTileOrder.indexOf(details.data);
          final to = quickTileOrder.indexOf(id);

          if (from < 0 || to < 0 || from == to) return;

          final moved = quickTileOrder.removeAt(from);
          quickTileOrder.insert(to, moved);
        });
      },
      builder: (context, candidates, rejected) {
        final highlighted = candidates.isNotEmpty;

        final wrapped = Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: child,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF070812).withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.drag_indicator,
                  size: 11,
                  color: color.withValues(alpha: 0.82),
                ),
              ),
            ),
          ],
        );

        return LongPressDraggable<String>(
          data: id,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.92,
              child: Transform.scale(scale: 1.03, child: child),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.28, child: wrapped),
          child: wrapped,
        );
      },
    );
  }

  Widget buildQuickSectionsPanel(Color c) {
    final titleCount = equippedTitleIds.length;
    final allyNames = activeAllies.isEmpty
        ? t('nessuno', 'none')
        : activeAllies
              .map((a) => widget.linguaInglese ? a.nameEn : a.nameIt)
              .take(2)
              .join(', ');
    final relicName = activeRelic == null
        ? '—'
        : widget.linguaInglese
        ? activeRelic!.nameEn
        : activeRelic!.nameIt;
    final artName = activeArt == null
        ? '—'
        : widget.linguaInglese
        ? activeArt!.nameEn
        : activeArt!.nameIt;
    final costumeName = activeCostume == null
        ? '—'
        : widget.linguaInglese
        ? activeCostume!.nameEn
        : activeCostume!.nameIt;

    Widget tileFor(String id) {
      switch (id) {
        case 'party':
          return draggableQuickTile(
            id: id,
            color: Colors.tealAccent,
            child: quickModernTile(
              title: t('Party', 'Party'),
              value: '${activeAllies.length}/$maxActiveAllies',
              subtitle: allyNames,
              icon: Icons.groups,
              color: Colors.tealAccent,
              onTap: runActive ? showAllyChoices : null,
            ),
          );

        case 'costume':
          return draggableQuickTile(
            id: id,
            color: const Color(0xFFFFD36A),
            child: quickModernTile(
              title: t('Costume', 'Costume'),
              value: costumeName,
              subtitle: t('scelto a inizio run', 'chosen at run start'),
              icon: Icons.checkroom,
              color: const Color(0xFFFFD36A),
            ),
          );

        case 'relic':
          return draggableQuickTile(
            id: id,
            color: const Color(0xFFFF5A3C),
            child: quickModernTile(
              title: t('Reliquia', 'Relic'),
              value: relicName,
              subtitle: canUseRelicOpen()
                  ? t('Open pronta', 'Open ready')
                  : t('Open chiusa', 'Open closed'),
              icon: Icons.stars,
              color: const Color(0xFFFF5A3C),
              onTap: runActive ? showRelicShortcutChoices : null,
            ),
          );

        case 'art':
          return draggableQuickTile(
            id: id,
            color: const Color(0xFF8B5CF6),
            child: quickModernTile(
              title: t('Arte', 'Art'),
              value: artName,
              subtitle: 'CD $artTechniqueCooldown',
              icon: Icons.auto_fix_high,
              color: const Color(0xFF8B5CF6),
              onTap: runActive ? showArtShortcutChoices : null,
            ),
          );

        case 'titles':
          return draggableQuickTile(
            id: id,
            color: const Color(0xFFA78BFA),
            child: quickModernTile(
              title: t('Titoli', 'Titles'),
              value: '$titleCount',
              subtitle: runActive
                  ? t('solo run', 'run only')
                  : t('chiusi', 'closed'),
              icon: Icons.workspace_premium,
              color: const Color(0xFFA78BFA),
              onTap: runActive ? showTitleChoices : null,
            ),
          );

        case 'bag':
          return draggableQuickTile(
            id: id,
            color: Colors.greenAccent,
            child: quickModernTile(
              title: t('Zaino', 'Bag'),
              value: '${inventoryDrops.length} drop',
              subtitle: 'Vitalium ${potionMinor + potionMajor}',
              icon: Icons.backpack,
              color: Colors.greenAccent,
              onTap: runActive ? showQuickInventory : null,
            ),
          );

        case 'drowned':
          return draggableQuickTile(
            id: id,
            color: const Color(0xFF60A5FA),
            child: quickModernTile(
              title: t('Affogati', 'Drowned'),
              value: '$activeTemporaryDrownedCount/$maxTemporaryDrowned',
              subtitle: activeTemporaryDrownedCount > 0
                  ? t('restano nel party', 'stay in party')
                  : t('nessun richiamo', 'no call'),
              icon: Icons.water_drop,
              color: const Color(0xFF60A5FA),
            ),
          );

        case 'kooba':
        default:
          return draggableQuickTile(
            id: 'kooba',
            color: const Color(0xFFFFD36A),
            child: quickModernTile(
              title: 'Kooba',
              value: '$sparklingGears',
              subtitle: t('ingranaggi da vendere', 'gears to sell'),
              icon: Icons.auto_awesome,
              color: const Color(0xFFFFD36A),
            ),
          );
      }
    }

    final header = Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: LinearGradient(
              colors: [c.withValues(alpha: 0.42), const Color(0xFF1A1530)],
            ),
            border: Border.all(color: c.withValues(alpha: 0.62)),
          ),
          child: Icon(Icons.visibility, color: c, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Occhio Rapido', 'Quick Eye'),
                style: const TextStyle(
                  color: Color(0xFFF4F0FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quickEyeCollapsed
                    ? t(
                        'Ridotto: solo sezioni rapide.',
                        'Collapsed: quick sections only.',
                      )
                    : t(
                        'Sezioni rapide trascinabili: tieni premuto il grab sulla card.',
                        'Draggable quick sections: hold the grab on a card.',
                      ),
                style: const TextStyle(
                  color: Color(0xFF9E94C4),
                  fontSize: 9.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => quickEyeCollapsed = !quickEyeCollapsed),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  quickEyeCollapsed ? Icons.unfold_more : Icons.unfold_less,
                  color: c,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  quickEyeCollapsed
                      ? t('Apri', 'Open')
                      : t('Riduci', 'Collapse'),
                  style: TextStyle(
                    color: c,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final safeOrder = [
      ...quickTileOrder.where(
        (id) => {
          'party',
          'costume',
          'relic',
          'art',
          'titles',
          'bag',
          'kooba',
          'drowned',
        }.contains(id),
      ),
      ...[
        'party',
        'costume',
        'relic',
        'art',
        'titles',
        'bag',
        'kooba',
        'drowned',
      ].where((id) => !quickTileOrder.contains(id)),
    ];

    return Container(
      padding: EdgeInsets.all(quickEyeCollapsed ? 9 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151426), Color(0xFF0B0C16), Color(0xFF080914)],
        ),
        border: Border.all(color: c.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            if (!quickEyeCollapsed) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: safeOrder.map(tileFor).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildDetailsPanel(Color c) {
    return collapsiblePanel(
      title: t('Dettagli run', 'Run details'),
      icon: Icons.tune,
      expanded: showDungeonDetails,
      color: c,
      onTap: () => setState(() => showDungeonDetails = !showDungeonDetails),
      child: Text(
        buildRunSummaryText(),
        style: const TextStyle(
          color: Color(0xFFBFB7DD),
          height: 1.35,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildLogPanel() {
    return collapsiblePanel(
      title: 'Log',
      icon: Icons.notes,
      expanded: showLogPanel,
      trailing: '${log.length}',
      color: Colors.blueGrey,
      onTap: () => setState(() => showLogPanel = !showLogPanel),
      child: SizedBox(
        height: 130,
        child: log.isEmpty
            ? Center(
                child: Text(
                  t('Il dungeon tace.', 'The dungeon is silent.'),
                  style: const TextStyle(
                    color: Color(0xFF8F86AD),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: log.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    cleanDungeonText(log[index]),
                    style: const TextStyle(
                      color: Color(0xFFE8E2FF),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget buildArtBoardPanel() {
    if (!showArtBoard) return const SizedBox.shrink();
    final runArtIds = <String>{
      ...selectedRunArtIds,
      if (activeArt != null) activeArt!.effectId,
    };
    final visibleArts = _allArts.where((art) {
      if (runActive) return runArtIds.contains(art.effectId);
      return art.unlockedByDefault || unlockedArtIds.contains(art.effectId);
    }).toList();

    return compactCard(
      borderColor: const Color(0xFFA78BFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'Artwork / Tavola delle 96 Oculum Art',
              'Artwork / Board of the 96 Oculum Arts',
            ),
            style: const TextStyle(
              color: Color(0xFFE8E2FF),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          if (visibleArts.isEmpty)
            Text(
              t(
                'Nessuna Art visibile ora: avvia una run e scegli l Art iniziale.',
                'No Arts visible now: start a run and pick your starting Art.',
              ),
              style: const TextStyle(
                color: Color(0xFF8F86AD),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          if (visibleArts.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleArts.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final art = visibleArts[index];
                final unlocked = runActive
                    ? runArtIds.contains(art.effectId)
                    : art.unlockedByDefault ||
                          unlockedArtIds.contains(art.effectId);
                final c = elementColor(art.elementId);

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: unlocked ? 0.18 : 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: c.withValues(alpha: unlocked ? 0.7 : 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        unlocked ? Icons.visibility : Icons.visibility_off,
                        color: c,
                        size: 23,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.linguaInglese ? art.nameEn : art.nameIt,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unlocked
                              ? const Color(0xFFE8E2FF)
                              : const Color(0xFF8F86AD),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget buildWeaponBoardPanel() {
    if (!showWeaponBoard) return const SizedBox.shrink();
    final runWeaponIds = <String>{if (starterWeapon != null) starterWeapon!.id};
    final visibleWeapons = _starterWeapons.where((weapon) {
      if (!canShowStoryLockedWeapon(weapon.id)) {
        return false;
      }
      if (runActive) return runWeaponIds.contains(weapon.id);
      return weapon.unlockedByDefault || unlockedWeaponIds.contains(weapon.id);
    }).toList();

    return compactCard(
      borderColor: const Color(0xFFFFD36A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Board Armi sbloccabili', 'Unlockable Weapon Board'),
            style: const TextStyle(
              color: Color(0xFFE8E2FF),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          if (visibleWeapons.isEmpty)
            Text(
              t(
                'Nessuna arma visibile ora: avvia una run e scegli l arma iniziale.',
                'No weapons visible now: start a run and pick your starting weapon.',
              ),
              style: const TextStyle(
                color: Color(0xFF8F86AD),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          if (visibleWeapons.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleWeapons.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 145,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final weapon = visibleWeapons[index];
                final unlocked = runActive
                    ? runWeaponIds.contains(weapon.id)
                    : weapon.unlockedByDefault ||
                          unlockedWeaponIds.contains(weapon.id);
                final c = elementColor(weapon.elementId);
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: unlocked ? 0.18 : 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: c.withValues(alpha: unlocked ? 0.7 : 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        unlocked ? Icons.gps_fixed : Icons.lock,
                        color: c,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.linguaInglese ? weapon.nameEn : weapon.nameIt,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unlocked
                              ? const Color(0xFFE8E2FF)
                              : const Color(0xFF8F86AD),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        elementName(weapon.elementId),
                        style: TextStyle(
                          color: c,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = statusColor();
    final mediaSize = MediaQuery.of(context).size;
    final phoneLandscape =
        mediaSize.shortestSide < 600 && mediaSize.width > mediaSize.height;

    return Dialog(
      backgroundColor: const Color(0xFF070812),
      insetPadding: EdgeInsets.all(phoneLandscape ? 0 : 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(phoneLandscape ? 0 : 24),
        side: BorderSide(color: c.withValues(alpha: 0.85), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final desktopLike = MediaQuery.of(context).size.width >= 900;
          final maxWidth = desktopLike ? 1440.0 : 820.0;
          final showChoicesNearCombat =
              inCombat && eventChoices.isNotEmpty && choicePanelMode != 'event';
          final listBuilders = <WidgetBuilder>[
            (_) => buildTopStatus(c),
            (_) => const SizedBox(height: 10),
            (_) => buildMainBars(c),
            (_) => const SizedBox(height: 10),
            (_) => buildSpriteStage(c),
            if (showSpritePanel) (_) => const SizedBox(height: 10),
            if (inCombat || showSpritePanel) ...[
              (_) =>
                  _OculumDungeonSkinSystem(this).buildDefinitiveCombatAddon(),
              (_) => const SizedBox(height: 10),
            ],
            if (showChoicesNearCombat) ...[
              (_) => buildEventChoicesPanel(),
              (_) => const SizedBox(height: 10),
            ],
            (_) => buildSpriteCodexPanel(c),
            if (showSpriteCodex) (_) => const SizedBox(height: 10),
            (_) => buildTrapMiniGamePanel(c),
            if (trapMiniGameActive) (_) => const SizedBox(height: 10),
            (_) => buildStoryBox(c),
            (_) => const SizedBox(height: 10),
            if (!showChoicesNearCombat) ...[
              (_) => buildEventChoicesPanel(),
              if (eventChoices.isNotEmpty) (_) => const SizedBox(height: 10),
            ],
            (_) => buildCombatActionsPanel(context, c),
            (_) => const SizedBox(height: 10),
            (_) => buildQuickSectionsPanel(c),
            (_) => const SizedBox(height: 10),
            (_) => buildArtBoardPanel(),
            if (showArtBoard) (_) => const SizedBox(height: 10),
            (_) => buildWeaponBoardPanel(),
            if (showWeaponBoard) (_) => const SizedBox(height: 10),
            (_) => buildDetailsPanel(c),
            (_) => const SizedBox(height: 10),
            (_) => buildLogPanel(),
          ];

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: phoneLandscape ? double.infinity : maxWidth,
              maxHeight: phoneLandscape ? double.infinity : 900,
            ),
            child: Padding(
              padding: EdgeInsets.all(phoneLandscape ? 8 : 12),
              child: ListView.builder(
                primary: false,
                cacheExtent: 360,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: listBuilders.length,
                itemBuilder: (context, index) => listBuilders[index](context),
              ),
            ),
          );
        },
      ),
    );
  }
}
