part of 'oculum_lite_run.dart';

enum LiteAttribute {
  resilienza(
    'Resilienza',
    'I punti guadagnati aumentano la Vita secondo il moltiplicatore del livello.',
  ),
  volonta(
    'Volontà',
    'Ogni punto guadagnato aggiunge 3 Danni all’arma e 0,4% di portata, fino al 12% di portata extra.',
  ),
  materia(
    'Materia',
    'Ogni punto guadagnato aggiunge 1% di schivata contro i proiettili diretti e 0,4% di velocità d’attacco, fino al 25% e al 12%.',
  ),
  oculum(
    'Oculum',
    'Ogni punto guadagnato aggiunge 1 alla riserva massima di Oculum.',
  );

  const LiteAttribute(this.label, this.description);

  final String label;
  final String description;
}

class LiteAttributes {
  const LiteAttributes({
    required this.resilienza,
    required this.volonta,
    required this.materia,
    required this.oculum,
  });

  final int resilienza;
  final int volonta;
  final int materia;
  final int oculum;

  static int resilienceMultiplier(int level) => (6 + level).clamp(6, 10);

  int get total => resilienza + volonta + materia + oculum;

  int operator [](LiteAttribute attribute) => switch (attribute) {
    LiteAttribute.resilienza => resilienza,
    LiteAttribute.volonta => volonta,
    LiteAttribute.materia => materia,
    LiteAttribute.oculum => oculum,
  };
}

const _liteAttributeBase = 10;
const _litePointsPerLevel = 4;
const _liteBaseLife = 100.0;

double _standardLifeAtFloor(int floor) {
  final cleared = max(0, floor);
  final expectedExperience = 110 * cleared + 3 * cleared * (cleared - 1) ~/ 2;
  final level = LiteRun.levelForExperience(expectedExperience);
  return _liteBaseLife +
      (level - 1) * (10 + LiteAttributes.resilienceMultiplier(level));
}

// The fixed style follows the sheet through transformations and resuming a run.
class _LiteAttributeGrowth {
  _LiteAttributeGrowth(this._profile, this.manual);

  LiteHero _profile;
  final bool manual;
  final _spent = List<int>.filled(LiteAttribute.values.length, 0);
  int _level = -1;
  late LiteAttributes _cached;

  static int _earned(int level) =>
      (level - 1).clamp(0, 10000) * _litePointsPerLevel;

  int unspent(int level) => manual
      ? max(0, _earned(level) - _spent.fold(0, (sum, amount) => sum + amount))
      : 0;

  bool allocate(LiteAttribute attribute, int level) {
    if (unspent(level) <= 0) return false;
    _spent[attribute.index]++;
    _level = -1;
    return true;
  }

  LiteAttributes at(int level) {
    if (_level != level) {
      final gains = manual ? _spent : _preset(level);
      _cached = LiteAttributes(
        resilienza: _liteAttributeBase + gains[0],
        volonta: _liteAttributeBase + gains[1],
        materia: _liteAttributeBase + gains[2],
        oculum: _liteAttributeBase + gains[3],
      );
      _level = level;
    }
    return _cached;
  }

  int gain(LiteAttribute attribute, int level) =>
      at(level)[attribute] - _liteAttributeBase;

  List<int> _preset(int level) {
    final tiers = _earned(level) ~/ _litePointsPerLevel;
    final primary = switch (_profile) {
      LiteHero.sentinella ||
      LiteHero.babyForestDemon ||
      LiteHero.slimeBlu ||
      LiteHero.cavaliereLunare ||
      LiteHero.guardiaSolare ||
      LiteHero.aberrazioneSolare ||
      LiteHero.armadilloCorazzato ||
      LiteHero.vesanybel => LiteAttribute.resilienza,
      LiteHero.ashley ||
      LiteHero.scostubandito ||
      LiteHero.granScostumato ||
      LiteHero.lithra ||
      LiteHero.vampiro ||
      LiteHero.reGoblin ||
      LiteHero.guardianoSolare ||
      LiteHero.demoneMinore ||
      LiteHero.demoneIntermedio ||
      LiteHero.demoneMaggiore ||
      LiteHero.vedettaEiva ||
      LiteHero.rasvyr ||
      LiteHero.fabbro => LiteAttribute.volonta,
      LiteHero.evasore ||
      LiteHero.dronePostea ||
      LiteHero.ombra ||
      LiteHero.raganella ||
      LiteHero.pipistrello ||
      LiteHero.pollo ||
      LiteHero.polloMeccanico ||
      LiteHero.ragnoSaldatore ||
      LiteHero.doppelganger ||
      LiteHero.lupoDiVaitern ||
      LiteHero.gablyn ||
      LiteHero.scostubanditoErrato ||
      LiteHero.scostubanditoVeteranoErrato => LiteAttribute.oculum,
      LiteHero.assassino => LiteAttribute.materia,
      LiteHero.duplicatore ||
      LiteHero.curatorePeste ||
      LiteHero.pyrel ||
      LiteHero.luce ||
      LiteHero.veyrth ||
      LiteHero.eliteSolare ||
      LiteHero.diavolo ||
      LiteHero.aerovyr ||
      LiteHero.pysciwarden ||
      LiteHero.lusierTre ||
      LiteHero.funerys ||
      LiteHero.moscaCampana => LiteAttribute.oculum,
    };
    final secondaries = [
      for (var offset = 1; offset < LiteAttribute.values.length; offset++)
        LiteAttribute.values[(primary.index + offset) %
            LiteAttribute.values.length],
    ];
    final gains = List.filled(LiteAttribute.values.length, 0);
    gains[primary.index] = tiers * 2;
    final cycles = tiers ~/ secondaries.length;
    final extra = tiers % secondaries.length;
    for (var index = 0; index < secondaries.length; index++) {
      gains[secondaries[index].index] =
          cycles * 2 + extra - (index < extra ? 1 : 0);
    }
    return gains;
  }

  Map<String, Object> get frame => {
    'profile': _profile.name,
    if (manual) 'spent': List<int>.of(_spent),
  };

  void restore(Object? value, int level) {
    if (value is! Map) return;
    _profile = _enum(LiteHero.values, value['profile'], _profile);
    _level = -1;
    if (!manual || value['spent'] is! List) return;
    final spent = value['spent'] as List;
    var remaining = _earned(level);
    for (var index = 0; index < _spent.length; index++) {
      final amount = index < spent.length
          ? _int(spent[index]).clamp(0, remaining)
          : 0;
      _spent[index] = amount;
      remaining -= amount;
    }
  }
}

extension LiteRunAttributes on LiteRun {
  LiteAttributes attributesOf([LiteCoopFighter? fighter]) =>
      (fighter?._attributes ?? _attributes).at(fighter?.level ?? level);

  int freeAttributePoints([LiteCoopFighter? fighter]) =>
      (fighter?._attributes ?? _attributes).unspent(fighter?.level ?? level);

  bool spendAttributePoint(
    LiteAttribute attribute, [
    LiteCoopFighter? fighter,
  ]) {
    if (finished ||
        (fighter?.hp ?? hp) <= 0 ||
        (fighter != null &&
            (!fighter.connected || !coopFighters.contains(fighter)))) {
      return false;
    }
    final previousLife = fighter?.maxHp ?? maxHp;
    final previousMana = fighter?.maxOculum ?? maxOculum;
    final growth = fighter?._attributes ?? _attributes;
    if (!growth.allocate(attribute, fighter?.level ?? level)) return false;
    if (fighter == null) {
      hp = min(maxHp, hp + max(0.0, maxHp - previousLife));
      oculum = min(maxOculum, oculum + max(0.0, maxOculum - previousMana));
    } else {
      fighter.hp = min(
        fighter.maxHp,
        fighter.hp + max(0.0, fighter.maxHp - previousLife),
      );
      fighter.oculum = min(
        fighter.maxOculum,
        fighter.oculum + max(0.0, fighter.maxOculum - previousMana),
      );
    }
    return true;
  }

  double attributeAttackSpeed([LiteCoopFighter? fighter]) =>
      1 + min(.12, _attributeGain(LiteAttribute.materia, fighter) * .004);

  double attributeAttackReach([LiteCoopFighter? fighter]) =>
      1 + min(.12, _attributeGain(LiteAttribute.volonta, fighter) * .004);

  double _attributeDamage([LiteCoopFighter? fighter]) =>
      3.0 * _attributeGain(LiteAttribute.volonta, fighter);

  double attributeDodgeChance([LiteCoopFighter? fighter]) =>
      min(.25, _attributeGain(LiteAttribute.materia, fighter) * .01);

  int _attributeGain(LiteAttribute attribute, [LiteCoopFighter? fighter]) =>
      (fighter?._attributes ?? _attributes).gain(
        attribute,
        fighter?.level ?? level,
      );

  bool _rollMateriaDodge(LiteProjectile shot, [LiteCoopFighter? fighter]) {
    if ((fighter?.hp ?? hp) <= 0 ||
        (fighter != null && openProtects(fighter.id)) ||
        shot.boomerang ||
        !switch (shot.kind) {
          LiteProjectileKind.normal ||
          LiteProjectileKind.pulse ||
          LiteProjectileKind.plasma ||
          LiteProjectileKind.frostBolt ||
          LiteProjectileKind.rifleBullet ||
          LiteProjectileKind.rifleCritical ||
          LiteProjectileKind.fireball ||
          LiteProjectileKind.solarBolt ||
          LiteProjectileKind.lunarCrescent => true,
          _ => false,
        }) {
      return false;
    }
    final chance = attributeDodgeChance(fighter);
    if (chance <= 0 || _rng.nextDouble() >= chance) return false;
    shot.hit.add(fighter == null ? -1 : -fighter.id - 2);
    if (fighter == null && hero == LiteHero.assassino) {
      _assassinQuiet = _assassinQuietDelay;
    } else if (fighter?.hero == LiteHero.assassino) {
      fighter!._assassinQuiet = _assassinQuietDelay;
    }
    _recordImpact(
      LiteImpactTarget.materiaDodge,
      fighter?.id ?? 0,
      fighter?.position ?? position,
    );
    return true;
  }
}
