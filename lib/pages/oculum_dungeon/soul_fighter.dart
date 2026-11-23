part of 'monster_book.dart';

const _soulFighterMonster = MonsterBookEntry(
  id: 'soul_fighter',
  nameIt: 'Combattente dell’Anima',
  nameEn: 'Soul Fighter',
  descIt:
      'Spadaccina mascherata. La sua lama spirituale recide il respiro e, nella veglia, una mano e un teschio prendono forma nella penombra.',
  descEn:
      'A masked swordfighter. Her spiritual blade cuts through breath, and a hand and a skull take shape in the shadows.',
  elementId: 'spirituale',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  planeIds: ['morti'],
  skillIds: ['soul_fighter_cut', 'soul_fighter_guard', 'soul_fighter_skull'],
  stats: {'level': 0, 'resilienza': 5, 'volonta': 7, 'materia': 5, 'oculum': 8},
  encounterRules: {'authoredCanonical': true, 'oculumArt': true},
  canWieldWeapons: true,
  weaponTags: ['spada'],
);

final _soulFighterEliteMonster = _soulFighterMonster.copyWith(
  id: 'soul_fighter_variante_elite',
  nameIt: 'Combattente dell’Anima Elité',
  nameEn: 'Elite Soul Fighter',
  descIt:
      'Spadaccina mascherata in piedi sotto un arco della cripta. Una mano e un teschio spettrali accompagnano la lama spirituale.',
  descEn:
      'A masked swordfighter beneath a crypt arch. A spectral hand and skull follow her spiritual blade.',
);
