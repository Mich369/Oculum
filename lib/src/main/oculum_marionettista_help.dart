part of '../../main.dart';

const oculumMarionettistaHelpPassiveId = 'marionettista_shared_help';
const _necthrallPublicHelp = 'necthrallHelpBonus';
const _necthrallGranted = 'necthrallHelpGranted';
const _necthrallHelpEffect = 'necthrall_combined_help';
const _necthrallHelpTiers = {0: 1, 3: 3, 10: 9, 25: 12};

CharacterSkill oculumMarionettistaHelpPassive() => CharacterSkill(
  id: oculumMarionettistaHelpPassiveId,
  nome: 'Legame di Necthrall',
  tipo: 'Passiva',
  costo: '',
  cooldown: '',
  descrizione: '',
  forme: [
    for (final tier in _necthrallHelpTiers.entries)
      CharacterSkillForm(
        nome: 'Livello ${tier.key}',
        tipo: 'Passiva',
        livello: '${tier.key}',
        costoStrutturato: OculumSkillCost(resource: 'nessuna'),
        descrizione:
            '+${tier.value} con Aiuta compagno. Tra chi tira e chi aiuta si '
            'applica una sola volta il bonus più alto.',
        effettiStrutturati: [
          OculumStructuredEffect(
            id: '${_necthrallHelpEffect}_${tier.key}',
            type: 'planar',
            target: _necthrallHelpEffect,
            valueExpression: '${tier.value}',
            recipient: 'se_stesso',
          ),
        ],
      ),
  ],
);

int oculumMarionettistaHelpValue(CharacterSkill? skill, int level) {
  if (skill == null ||
      skill.id != oculumMarionettistaHelpPassiveId ||
      !skill.passiva) {
    return 0;
  }
  CharacterSkillForm? selected;
  var selectedLevel = -1;
  for (final form in skill.forme) {
    final threshold = int.tryParse(form.livello.trim());
    if (threshold == null || threshold < selectedLevel || threshold > level) {
      continue;
    }
    selected = form;
    selectedLevel = threshold;
  }
  final effect = selected?.effettiStrutturati
      .where(
        (effect) => effect.enabled && effect.target == _necthrallHelpEffect,
      )
      .firstOrNull;
  return (int.tryParse(effect?.valueExpression.trim() ?? '') ?? 0)
      .clamp(0, 1000000)
      .toInt();
}

int oculumMarionettistaCombinedHelpBonus({
  required int rollerBonus,
  required Iterable<int> helperBonuses,
}) {
  if (helperBonuses.isEmpty) return 0;
  return helperBonuses.fold<int>(max(0, rollerBonus), max);
}

extension _OculumMarionettistaHelp on _OculumHomePageState {
  bool _grantMarionettistaHelp(int index) {
    final sheet = schedePersonaggio[index];
    if (sheet[_necthrallGranted] == true) return false;
    sheet[_necthrallGranted] = true;
    final passive = oculumMarionettistaHelpPassive();
    if (index == schedaCorrente) {
      if (skills.any((skill) => skill.id == passive.id)) return false;
      skills.add(passive);
      invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    } else {
      final saved = (sheet['skills'] as List? ?? const []).toList();
      if (saved.whereType<Map>().any((item) => item['id'] == passive.id)) {
        return false;
      }
      sheet['skills'] = [...saved, passive.toJson()];
      final public = sheet['faunaPublic'];
      sheet['faunaPublic'] = {
        if (public is Map) ...Map<String, dynamic>.from(public),
        _necthrallPublicHelp: _marionettistaHelpValueAt(index),
      };
    }
    combatLogFor(
      sheetTagAt(index),
      '[VITTORIA] Passiva appresa · ${passive.nome}.',
    );
    return true;
  }

  int _marionettistaHelpValueAt(int index) {
    if (index == schedaCorrente) {
      return oculumMarionettistaHelpValue(
        skills
            .where((skill) => skill.id == oculumMarionettistaHelpPassiveId)
            .firstOrNull,
        max(0, leggiNumero(livelloController)),
      );
    }
    final sheet = schedePersonaggio[index];
    final raw = (sheet['skills'] as List? ?? const [])
        .whereType<Map>()
        .where((skill) => skill['id'] == oculumMarionettistaHelpPassiveId)
        .firstOrNull;
    return oculumMarionettistaHelpValue(
      raw == null
          ? null
          : CharacterSkill.fromJson(Map<String, dynamic>.from(raw)),
      max(0, readIntValue(sheet['livello'])),
    );
  }

  int _marionettistaPendingHelp(int index) {
    final sheet = schedePersonaggio[index];
    final raw = (sheet['combatHelpPendingContributions'] as List? ?? const [])
        .whereType<Map>()
        .where((part) => '${part['id'] ?? ''}'.isNotEmpty);
    final sources =
        {
          for (final part in raw) '${part['sourceTag'] ?? ''}',
          // Older saves had the cumulative total and source tags, but no packets.
          if (raw.isEmpty && readIntValue(sheet['combatHelpPending']) != 0)
            ...(sheet['combatHelpPendingSources'] as List? ?? const [])
                .whereType<String>(),
        }..removeWhere(
          (tag) =>
              tag.isEmpty || oculumSameSheetIdentity(tag, sheetTagAt(index)),
        );
    if (sources.isEmpty) return 0;
    final tokens = onlineCombatTokens();
    return oculumMarionettistaCombinedHelpBonus(
      rollerBonus: _marionettistaHelpValueAt(index),
      helperBonuses: sources.map((tag) {
        final helperIndex = localSheetIndexForOculumTag(tag);
        if (helperIndex >= 0 && sheetIsOwnLocalSheetAt(helperIndex)) {
          return _marionettistaHelpValueAt(helperIndex);
        }
        // The existing Master snapshot projects the helper's owned-sheet data.
        // A Help message itself does not supply the passive or its value.
        final token = tokens
            .where((token) => combatTokenMatchesSheet(token, tag))
            .firstOrNull;
        final public = token?['faunaPublic'];
        return public is Map
            ? readIntValue(
                public[_necthrallPublicHelp],
              ).clamp(0, 1000000).toInt()
            : 0;
      }),
    );
  }

  int _pendingCombatHelpAt(int index) =>
      readIntValue(
        schedePersonaggio[index]['combatHelpPending'],
      ).clamp(-1000000, 1000000).toInt() +
      _marionettistaPendingHelp(index);
}
