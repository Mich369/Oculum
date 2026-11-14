enum OculumRollRescue { base, superInspiration, oculum, fortune, pact }

int oculumBaseInspirationCost({required bool chainedFate}) =>
    chainedFate ? 2 : 1;

Set<OculumRollRescue> oculumRollRescueOptions({
  required bool failed,
  required bool negativeCritical,
  bool positiveCritical = false,
  int? natural,
  int base = 0,
  int superInspiration = 0,
  int oculum = 0,
  int fortune = 0,
  bool fortuneCanHelp = false,
  bool pactAvailable = false,
  bool inspirationUsed = false,
  bool chainedFate = false,
}) {
  if (!failed) return const {};
  final ordinary = !negativeCritical && !positiveCritical;
  final baseEligible = natural == null
      ? ordinary
      : natural >= 2 && natural <= 19;
  return {
    if (!inspirationUsed) ...{
      if (baseEligible &&
          base >= oculumBaseInspirationCost(chainedFate: chainedFate))
        OculumRollRescue.base,
      if (superInspiration > 0) OculumRollRescue.superInspiration,
      if (negativeCritical && oculum > 0) OculumRollRescue.oculum,
    },
    if (fortuneCanHelp && fortune > 0) OculumRollRescue.fortune,
    if (pactAvailable && (ordinary || negativeCritical)) OculumRollRescue.pact,
  };
}

int oculumInspirationCriticalNatural({
  required int faces,
  required int percentile,
}) => percentile < 50 ? faces : 1;
