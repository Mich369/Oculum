part of 'monster_book.dart';

const oculumSonoreyeId = 'sonoreye';
const oculumSonoreyeEchoSkill = 'sonoreye_eco_intracranica';
const oculumSonoreyeBellSkill = 'sonoreye_rintocco_arresto';
const oculumSonoreyeBellPart = 'sonoreye_bell';
const oculumSonoreyeEchoMinimumEffect = 'sonoreye_echo_minimum';

int oculumSonoreyeEchoDamageFloor(int damage, int percent) =>
    (max(0, damage) * percent.clamp(0, 100) + 99) ~/ 100;

bool oculumSonoreyeBellIsBroken(Map anatomy) {
  final parts = anatomy['parts'];
  final bell = parts is Map ? parts[oculumSonoreyeBellPart] : null;
  if (bell is! Map) return false;
  final maximum = bell['maximumHp'];
  final damage = bell['damageTaken'];
  return maximum is num && maximum > 0 && damage is num && damage >= maximum;
}

bool oculumIsSonoreyeBellEffect(String id) =>
    id.split('/').last.startsWith('${oculumSonoreyeBellSkill}_forma_');

bool oculumIsSonoreyeEchoEffect(String id) =>
    id.split('/').last.startsWith('${oculumSonoreyeEchoSkill}_forma_');

const _sonoreyeMonster = MonsterBookEntry(
  id: oculumSonoreyeId,
  nameIt: 'Sonoreye',
  nameEn: 'Sonoreye',
  descIt:
      'Creatura con un occhio al centro di ciascun cerchio. Usa la campana per il Rintocco d’arresto e il Suono per l’Eco intracranica.',
  descEn:
      'A creature with one eye at the centre of each ring. It uses its bell for Arresting Chime and sound for Intracranial Echo.',
  elementId: 'suono',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  stats: {'oculum': 13, 'oculumArt': 1},
  skillIds: [oculumSonoreyeEchoSkill, oculumSonoreyeBellSkill],
  encounterRules: {
    'authoredCanonical': true,
    'precisionBodyParts': [
      {'id': 'body', 'group': 'body', 'label': 'Corpo', 'penalty': 0},
      {
        'id': oculumSonoreyeBellPart,
        'group': 'bell',
        'label': 'Campana',
        'penalty': 0,
        'material': 'metal',
      },
    ],
  },
);

const _sonoreyeTechniques = <String, MonsterConcreteTechnique>{
  oculumSonoreyeEchoSkill: MonsterConcreteTechnique(
    name: 'Eco intracranica',
    action:
        'Colpisci un avversario col Suono. Dalla forma II l’eco infligge almeno il 50% dei Danni anche con difesa o schivata riuscita, prima di Scudi e resistenze',
    element: 'suono',
    kind: 'attacco',
    requiredLevel: 0,
    minimums: [2, 4, 6],
    maximums: [2, 4, 6],
    cooldownValues: [2, 3, 4],
    forms: [
      [
        MonsterTechniqueEffect(
          'danno',
          '0',
          mode: 'prossima_azione',
          recipient: 'nemico',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'danno',
          '0',
          mode: 'prossima_azione',
          recipient: 'nemico',
        ),
        MonsterTechniqueEffect(
          'planar',
          '50',
          target: oculumSonoreyeEchoMinimumEffect,
          mode: 'prossima_azione',
          recipient: 'nemico',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'danno',
          '0',
          mode: 'prossima_azione',
          recipient: 'nemico',
        ),
        MonsterTechniqueEffect(
          'planar',
          '50',
          target: oculumSonoreyeEchoMinimumEffect,
          mode: 'prossima_azione',
          recipient: 'nemico',
        ),
      ],
    ],
  ),
  oculumSonoreyeBellSkill: MonsterConcreteTechnique(
    name: 'Rintocco d’arresto',
    action:
        'Fai risuonare la campana e stordisci un avversario. Se la campana si rompe la tecnica diventa indisponibile',
    element: 'suono',
    kind: 'controllo',
    requiredLevel: 0,
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cooldownValues: [3, 4, 5],
    forms: [
      [
        MonsterTechniqueEffect(
          'stato',
          '1',
          target: 'stordito',
          mode: 'turni',
          recipient: 'nemico',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'stato',
          '1',
          target: 'stordito',
          mode: 'turni',
          recipient: 'nemico',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'stato',
          '1',
          target: 'stordito',
          mode: 'turni',
          recipient: 'nemico',
        ),
      ],
    ],
  ),
};
