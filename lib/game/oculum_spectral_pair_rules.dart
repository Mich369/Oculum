const oculumAlbashardId = 'albashard';
const oculumAtrawispId = 'atrawisp';
const oculumAlbashardRingPart = 'albashard_ring';
const oculumAtrawispFirstAnchorPart = 'atrawisp_anchor_1';
const oculumAtrawispSecondAnchorPart = 'atrawisp_anchor_2';

typedef OculumSpectralPairBonus = ({String targetTag, String stat, int amount});

/// One pair in one Fight. Runtime callers must group all confirmed deaths from
/// the same effect before recording them, including multihit and area effects.
class OculumSpectralPair {
  const OculumSpectralPair({
    required this.fightId,
    required this.albashardTag,
    required this.atrawispTag,
    this.firstDeathEffectId,
  });

  final String fightId;
  final String albashardTag;
  final String atrawispTag;
  final String? firstDeathEffectId;

  bool _inFight(String activeFightId) =>
      fightId.isNotEmpty &&
      activeFightId == fightId &&
      albashardTag.isNotEmpty &&
      atrawispTag.isNotEmpty &&
      albashardTag != atrawispTag;

  bool canUseScagliaDiVeglia({
    required String activeFightId,
    required String sourceTag,
    required String targetTag,
  }) =>
      _inFight(activeFightId) &&
      sourceTag == albashardTag &&
      (targetTag == albashardTag || targetTag == atrawispTag);

  ({OculumSpectralPair pair, OculumSpectralPairBonus? bonus}) settleDeaths({
    required String activeFightId,
    required String effectId,
    required Set<String> confirmedDeadTags,
  }) {
    if (!_inFight(activeFightId) ||
        effectId.isEmpty ||
        firstDeathEffectId != null) {
      return (pair: this, bonus: null);
    }
    final albashardDied = confirmedDeadTags.contains(albashardTag);
    final atrawispDied = confirmedDeadTags.contains(atrawispTag);
    if (!albashardDied && !atrawispDied) return (pair: this, bonus: null);
    return (
      pair: OculumSpectralPair(
        fightId: fightId,
        albashardTag: albashardTag,
        atrawispTag: atrawispTag,
        firstDeathEffectId: effectId,
      ),
      bonus: albashardDied == atrawispDied
          ? null
          : albashardDied
          ? (targetTag: atrawispTag, stat: 'volonta', amount: 6)
          : (targetTag: albashardTag, stat: 'materia', amount: 6),
    );
  }
}
