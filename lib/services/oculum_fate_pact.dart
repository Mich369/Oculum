enum OculumFatePactOutcome { base, superInspiration, oculumChoice }

OculumFatePactOutcome oculumFatePactOutcome({
  required bool negativeCritical,
  required int percentile,
}) {
  if (!negativeCritical) return OculumFatePactOutcome.base;
  return percentile < 20
      ? OculumFatePactOutcome.oculumChoice
      : OculumFatePactOutcome.superInspiration;
}
