part of '../../main.dart';

const oculumSoulFighterId = 'soul_fighter';
const oculumSoulFighterEliteId = 'soul_fighter_variante_elite';
const oculumSoulFighterCutEffect = 'soul_fighter_current_life';
const oculumAnymareapEffect = 'soul_fighter_anymareap';

bool oculumIsSoulFighter(String id) =>
    id == oculumSoulFighterId || id == oculumSoulFighterEliteId;

bool oculumIsAnymareapArt(CharacterArt art) => art.skills.any(
  (skill) => skill.effettiPerLivello.any(
    (effects) => effects.any((effect) => effect.id == oculumAnymareapEffect),
  ),
);

int oculumSoulFighterDamage({required int currentHp, required int percent}) =>
    max(0, currentHp) * percent.clamp(0, 100) ~/ 100;

CharacterArt oculumAnymareapArt() => CharacterArt(
  nome: 'Anymareap',
  tipo: 'Oculum Art',
  descrizione: 'Il teschio spettrale attraversa le anime dei nemici.',
  sbloccata: true,
  skills: [
    _soulFighterSkill(
      name: 'Anymareap',
      description:
          'Un’Azione. Scegli da uno a tre nemici distinti. '
          'Ripartisci i Danni base spirituali fra i bersagli scelti, '
          'arrotondando ogni quota per eccesso. Ognuno risolve la propria difesa.',
      cost: 4,
      recovery: 4,
      role: 'Attacco',
      effect: OculumStructuredEffect(
        id: oculumAnymareapEffect,
        type: 'danno',
        target: 'danni',
        elementType: 'spirituale',
        valueExpression: '0',
        mode: 'immediato',
        recipient: 'nemico',
        minimumTargets: 1,
        maximumTargets: 3,
      ),
    ),
  ],
);

CharacterArt oculumSoulFighterArt(Iterable<String> selectedIds) => CharacterArt(
  nome: 'Filo dell’Ultimo Respiro',
  tipo: 'Oculum Art',
  descrizione:
      'La lama colpisce l’anima. Scudi e resistenze proteggono il bersaglio.',
  sbloccata: true,
  skills: [
    if (selectedIds.contains('soul_fighter_cut'))
      _soulFighterSkill(
        name: 'Taglio dell’Ultimo Respiro',
        description:
            'Danni spirituali pari al 20% della Vita attuale del bersaglio.',
        cost: 3,
        recovery: 4,
        role: 'Attacco',
        effect: OculumStructuredEffect(
          id: oculumSoulFighterCutEffect,
          type: 'danno_percentuale',
          elementType: 'spirituale',
          valueExpression: '20',
          mode: 'immediato',
          recipient: 'nemico',
          minimumTargets: 1,
          maximumTargets: 1,
        ),
      ),
  ],
);

List<CharacterArt> oculumMonsterBookAdditionalArts(
  MonsterBookEntry monster,
) => [
  if (oculumIsSoulFighter(monster.id))
    CharacterArt(
      nome: 'Veglia delle Anime Senza Nome',
      tipo: 'Oculum Art',
      descrizione:
          'La mano spettrale protegge e il teschio scopre il punto debole del nemico.',
      sbloccata: true,
      skills: [
        _soulFighterSkill(
          name: 'Mano della Veglia',
          description: 'Conferisce 12 Scudo Oculum a un alleato.',
          cost: 2,
          recovery: 3,
          role: 'Supporto',
          effect: OculumStructuredEffect(
            id: 'soul_fighter_guard',
            type: 'scudo',
            target: 'scudo_oculum',
            valueExpression: '12',
            recipient: 'alleato',
            minimumTargets: 1,
            maximumTargets: 1,
          ),
        ),
        _soulFighterSkill(
          name: 'Marchio dei Senza Nome',
          description:
              'Un colpo spirituale riduce di 3 la Difesa del bersaglio per un turno.',
          cost: 2,
          recovery: 3,
          role: 'Attacco',
          effect: OculumStructuredEffect(
            id: 'soul_fighter_skull',
            type: 'difesa',
            target: 'difesa',
            elementType: 'spirituale',
            valueExpression: '-3',
            mode: 'temporaneo',
            duration: '1',
            recipient: 'nemico',
            minimumTargets: 1,
            maximumTargets: 1,
          ),
        ),
      ],
    ),
  if (monster.id == oculumSoulFighterEliteId) oculumAnymareapArt(),
];

ArtSkill _soulFighterSkill({
  required String name,
  required String description,
  required int cost,
  required int recovery,
  required String role,
  required OculumStructuredEffect effect,
}) => ArtSkill(
  nome: name,
  livello: 1,
  evo1: description,
  oculumMinimiPerLivello: [cost],
  oculumMassimiPerLivello: [cost],
  tipiPerLivello: [role],
  effettiPerLivello: [
    [effect],
  ],
  cooldownPerLivello: [OculumAbilityCooldown(amount: recovery)],
);
