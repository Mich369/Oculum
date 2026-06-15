part of '../oculum_dungeon_game.dart';

class _DungeonChoice {
  const _DungeonChoice({
    required this.labelIt,
    required this.labelEn,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String labelIt;
  final String labelEn;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
}

class _GradeEventDef {
  const _GradeEventDef({
    required this.id,
    required this.grade,
    required this.titleIt,
    required this.titleEn,
    required this.descIt,
    required this.descEn,
    required this.icon,
  });

  final String id;
  final int grade;
  final String titleIt;
  final String titleEn;
  final String descIt;
  final String descEn;
  final IconData icon;
}

class _ElementDef {
  const _ElementDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.color,
    required this.verbIt,
    required this.verbEn,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final Color color;
  final String verbIt;
  final String verbEn;
}

class _DungeonArt {
  const _DungeonArt({
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.effectId,
    required this.elementId,
    required this.unlockedByDefault,
    required this.index,
  });

  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String effectId;
  final String elementId;
  final bool unlockedByDefault;
  final int index;
}

class _CharacterOrigin {
  const _CharacterOrigin({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.spriteKind,
    required this.primaryColor,
    required this.hpBonus,
    required this.shieldBonus,
    required this.damageBonus,
    required this.defenseBonus,
    required this.oculumBonus,
    required this.partnerNameIt,
    required this.partnerNameEn,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String spriteKind;
  final Color primaryColor;
  final int hpBonus;
  final int shieldBonus;
  final int damageBonus;
  final int defenseBonus;
  final int oculumBonus;
  final String partnerNameIt;
  final String partnerNameEn;
}

class _ArtSkillDef {
  const _ArtSkillDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.kind,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;

  /// damage, defense, heal, control, utility, special
  final String kind;
}

class _ArtSkillProgress {
  _ArtSkillProgress({required this.skillId});

  final String skillId;
  int level = 0;

  bool get unlocked => level > 0;
  bool get fullyUpgraded => level >= 3;
}

class _StarterWeapon {
  const _StarterWeapon({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.damageBonus,
    required this.defenseBonus,
    required this.shieldBonus,
    required this.oculumBonus,
    required this.oculumCharges,
    required this.elementId,
    this.unlockedByDefault = false,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final int damageBonus;
  final int defenseBonus;
  final int shieldBonus;
  final int oculumBonus;
  final int oculumCharges;
  final String elementId;
  final bool unlockedByDefault;
}

class _RunCostume {
  const _RunCostume({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.hpBonus,
    required this.shieldBonus,
    required this.defenseBonus,
    required this.damageBonus,
    required this.oculumBonus,
    required this.critBonus,
    required this.elementId,
    this.unlockedByDefault = false,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final int hpBonus;
  final int shieldBonus;
  final int defenseBonus;
  final int damageBonus;
  final int oculumBonus;
  final int critBonus;
  final String elementId;
  final bool unlockedByDefault;
}

class _EquipmentSetDef {
  const _EquipmentSetDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.weaponIds,
    required this.costumeIds,
    this.damageBonus = 0,
    this.defenseBonus = 0,
    this.shieldBonus = 0,
    this.oculumBonus = 0,
    this.critBonus = 0,
    this.victoryChanceBonus = 0,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final Set<String> weaponIds;
  final Set<String> costumeIds;
  final int damageBonus;
  final int defenseBonus;
  final int shieldBonus;
  final int oculumBonus;
  final int critBonus;
  final int victoryChanceBonus;

  bool matches(_StarterWeapon? weapon, _RunCostume? costume) {
    if (weapon == null || costume == null) return false;
    return weaponIds.contains(weapon.id) && costumeIds.contains(costume.id);
  }
}

class _EnemyTemplate {
  const _EnemyTemplate({
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.elementId,
    required this.hpMod,
    required this.atkMod,
    required this.defMod,
    this.boss = false,
  });

  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String elementId;
  final int hpMod;
  final int atkMod;
  final int defMod;
  final bool boss;
}

class _EnemyInstance {
  _EnemyInstance({
    required this.nameIt,
    required this.nameEn,
    required this.elementId,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.boss,
    required this.elite,
    required this.fetal,
    this.level = 1,
    this.grade = 0,
    this.originalPower = 0,
    Set<String>? adaptedAttackTypes,
    this.monsterId,
    List<String>? skillIds,
    List<String>? dropIds,
    this.spriteAssetPath,
    this.stunTurns = 0,
    this.slowTurns = 0,
    this.burnTurns = 0,
    this.bleedTurns = 0,
    this.attackDebuffTurns = 0,
    this.defenseDebuffTurns = 0,
    this.attackDebuffValue = 0,
    this.defenseDebuffValue = 0,
    this.burnPotency = 0,
    this.bleedPotency = 0,
  }) : adaptedAttackTypes = adaptedAttackTypes ?? <String>{} {
    this.skillIds = skillIds ?? [];
    this.dropIds = dropIds ?? [];
  }

  String? monsterId;
  List<String> skillIds = [];
  List<String> dropIds = [];
  String? spriteAssetPath;
  int stunTurns;
  int slowTurns;
  int burnTurns;
  int bleedTurns;
  int attackDebuffTurns;
  int defenseDebuffTurns;
  int attackDebuffValue;
  int defenseDebuffValue;
  int burnPotency;
  int bleedPotency;

  String nameIt;
  String nameEn;
  String elementId;
  int hp;
  int maxHp;
  int attack;
  int defense;
  bool boss;
  bool elite;
  bool fetal;
  int level;
  int grade;
  int originalPower;
  Set<String> adaptedAttackTypes;
  String? copiedArtId;
}

class _GoodNpc {
  const _GoodNpc({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.role,
    required this.elementId,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;

  /// striker, healer, guard, buffer, occult
  final String role;
  final String elementId;
}

class _AchievementDef {
  const _AchievementDef({
    required this.id,
    required this.titleIt,
    required this.titleEn,
    required this.descIt,
    required this.descEn,
    required this.rewardIt,
    required this.rewardEn,
    required this.rewardType,
    required this.rewardId,
    this.hidden = false,
  });

  final String id;
  final String titleIt;
  final String titleEn;
  final String descIt;
  final String descEn;
  final String rewardIt;
  final String rewardEn;
  final String rewardType; // art, weapon, npc, oculum
  final String rewardId;
  final bool hidden;
}

class _ShopItem {
  const _ShopItem({
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.costObser,
    required this.costDust,
    required this.effectId,
    this.elementId = 'neutral',
    this.resist = 0,
    this.firstThreeRunsOnly = false,
  });

  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final int costObser;
  final int costDust;
  final String effectId;
  final String elementId;
  final int resist;
  final bool firstThreeRunsOnly;
}

class _UniqueDrop {
  const _UniqueDrop({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.elementId,
    required this.damageBonus,
    required this.defenseBonus,
    required this.resistBonus,
    required this.sellObser,
    required this.sellDust,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String elementId;
  final int damageBonus;
  final int defenseBonus;
  final int resistBonus;
  final int sellObser;
  final int sellDust;
}

class _TitleDef {
  const _TitleDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.blindSpotIt,
    required this.blindSpotEn,
    required this.res,
    required this.vol,
    required this.mat,
    required this.ocu,
    required this.damage,
    required this.defense,
    this.strong = false,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String blindSpotIt;
  final String blindSpotEn;
  final int res;
  final int vol;
  final int mat;
  final int ocu;
  final int damage;
  final int defense;
  final bool strong;
}

class _RelicDef {
  const _RelicDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descIt,
    required this.descEn,
    required this.effectId,
    this.unlockedByDefault = false,
    this.requiresNoTavernkeeper = false,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descIt;
  final String descEn;
  final String effectId;
  final bool unlockedByDefault;
  final bool requiresNoTavernkeeper;
}

class _DifficultyOption {
  const _DifficultyOption({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.multiplier,
    required this.unlockedByDefault,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final double multiplier;
  final bool unlockedByDefault;
}

class _AttachedDrop {
  const _AttachedDrop({
    required this.dropId,
    required this.nameIt,
    required this.nameEn,
    required this.elementId,
    required this.damageBonus,
    required this.defenseBonus,
    required this.resistBonus,
  });

  final String dropId;
  final String nameIt;
  final String nameEn;
  final String elementId;
  final int damageBonus;
  final int defenseBonus;
  final int resistBonus;
}
