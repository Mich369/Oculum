part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

typedef _ReviewedSheetRoll = ({
  int natural,
  int total,
  int fortune,
  String note,
});

class _SheetRollReview {
  _SheetRollReview({
    required this.label,
    required this.natural,
    required this.faces,
    required this.total,
    required this.totalForNatural,
    required this.succeeds,
    required this.isCurrent,
    required this.chainedFate,
    required this.reservedFortune,
  });

  final String label;
  final int faces;
  final int Function(int) totalForNatural;
  final bool Function(int, int) succeeds;
  final bool Function() isCurrent;
  final bool chainedFate;
  final int reservedFortune;
  final completion = Completer<_ReviewedSheetRoll?>();
  int natural;
  int total;
  int fortune = 0;
  bool fortuneWasSpent = false;
  int fortuneSelection = 1;
  bool inspirationUsed = false;
  bool busy = false;
  bool confirmWhenReady = false;
  bool revealed = false;
  String note = '';

  bool get failed => !succeeds(natural, total);
  _ReviewedSheetRoll get result =>
      (natural: natural, total: total, fortune: fortune, note: note);
}

extension _OculumSheetRollReview on _OculumHomePageState {
  bool requireConfirmedSheetRoll() {
    if (!mounted) return false;
    if (sheetRollReview == null) return true;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          t(
            'Conferma prima il tiro in sospeso.',
            'Confirm the pending roll first.',
          ),
        ),
      ),
    );
    return false;
  }

  Future<_ReviewedSheetRoll?> reviewFailedSheetRoll({
    required String label,
    required int natural,
    required int faces,
    required int total,
    required int Function(int) totalForNatural,
    required bool Function(int natural, int total) succeeds,
    int reservedFortune = 0,
    bool fortuneAlreadyUsed = false,
    bool Function()? canCommit,
  }) async {
    final index = schedaCorrente;
    if (!mounted || sheetRollReview != null || canCommit?.call() == false) {
      return null;
    }
    final origin = currentSheetScrollId();
    final tag = sheetTagAt(index);
    final scope = permissionScope;
    final encounter = onlineCombatEncounterId;
    bool current() =>
        mounted &&
        currentSheetScrollId() == origin &&
        permissionScope == scope &&
        onlineCombatEncounterId == encounter &&
        sheetTagAt(index) == tag &&
        canCommit?.call() != false;
    final review = _SheetRollReview(
      label: label,
      natural: natural,
      faces: faces,
      total: total,
      totalForNatural: totalForNatural,
      succeeds: succeeds,
      isCurrent: current,
      chainedFate: chainedFateExperienceMultiplier() > 1,
      reservedFortune: reservedFortune,
    )..fortuneWasSpent = fortuneAlreadyUsed;
    if (_sheetRollOptions(review).isEmpty) return review.result;
    sheetRollReview = review;
    notifyDiceResultChanged();
    return review.completion.future;
  }

  int _sheetRollFortune(_SheetRollReview review) =>
      max(0, fortuna - review.reservedFortune);

  bool _sheetRollFortuneCanHelp(_SheetRollReview review, int available) {
    if (review.fortuneWasSpent || available <= 0) return false;
    return review.natural != 1 ||
        review.succeeds(review.natural, review.total + available);
  }

  Set<OculumRollRescue> _sheetRollOptions(_SheetRollReview review) {
    if (!review.isCurrent() || !canSpendMagicalLuckAt(schedaCorrente)) {
      return {};
    }
    final availableFortune = _sheetRollFortune(review);
    return oculumRollRescueOptions(
      failed: review.failed,
      negativeCritical: review.natural == 1,
      positiveCritical: review.natural == review.faces,
      natural: review.natural,
      base: leggiNumero(ispirazioniController),
      superInspiration: leggiNumero(superIspirazioniController),
      oculum: leggiNumero(ispirazioniOculumController),
      fortune: availableFortune,
      fortuneCanHelp: _sheetRollFortuneCanHelp(review, availableFortune),
      pactAvailable: !identityIsChaos && !fatePactUsed,
      inspirationUsed: review.inspirationUsed,
      chainedFate: review.chainedFate,
    );
  }

  void cancelPendingSheetRollReview() {
    final review = sheetRollReview;
    sheetRollReview = null;
    if (review != null && !review.completion.isCompleted) {
      review.completion.complete(null);
    }
  }

  void _confirmSheetRoll(_SheetRollReview review) {
    if (!identical(sheetRollReview, review)) return;
    if (review.busy) {
      review.confirmWhenReady = true;
      return;
    }
    if (!review.isCurrent()) {
      cancelPendingSheetRollReview();
    } else {
      sheetRollReview = null;
      review.completion.complete(review.result);
    }
    notifyDiceResultChanged();
  }

  String _sheetRollRescueLabel(OculumRollRescue choice) => switch (choice) {
    OculumRollRescue.base => inspirationLabelForType('base'),
    OculumRollRescue.superInspiration => inspirationLabelForType('super'),
    OculumRollRescue.oculum => inspirationLabelForType('oculum'),
    OculumRollRescue.fortune => t('Fortuna magica', 'Magical Luck'),
    OculumRollRescue.pact => t('Patto del Fato', 'Pact with Fate'),
  };

  int _sheetRollReplacement(_SheetRollReview review, {bool critical = false}) {
    final random = sheetRollRescueRandom ?? Random.secure();
    if (critical) {
      return oculumInspirationCriticalNatural(
        faces: review.faces,
        percentile: random.nextInt(100),
      );
    }
    final rolled = random.nextInt(review.faces) + 1;
    return rolled == 1 && hasFateKatana ? 2 : rolled;
  }

  void _replaceSheetRoll(_SheetRollReview review, int natural) {
    review.natural = natural;
    review.total = review.totalForNatural(natural) + review.fortune;
  }

  Future<void> _useSheetRollRescue(
    _SheetRollReview review,
    OculumRollRescue choice,
  ) async {
    if (!identical(sheetRollReview, review) ||
        review.busy ||
        !_sheetRollOptions(review).contains(choice)) {
      return;
    }
    review.busy = true;
    final label = _sheetRollRescueLabel(choice);
    var keepsRoll = false;
    try {
      switch (choice) {
        case OculumRollRescue.base:
        case OculumRollRescue.superInspiration:
        case OculumRollRescue.oculum:
          final controller = switch (choice) {
            OculumRollRescue.base => ispirazioniController,
            OculumRollRescue.superInspiration => superIspirazioniController,
            _ => ispirazioniOculumController,
          };
          final cost = choice == OculumRollRescue.base
              ? oculumBaseInspirationCost(chainedFate: review.chainedFate)
              : 1;
          controller.text = '${leggiNumero(controller) - cost}';
          review.inspirationUsed = true;
          _replaceSheetRoll(
            review,
            _sheetRollReplacement(
              review,
              critical: choice == OculumRollRescue.oculum,
            ),
          );
        case OculumRollRescue.fortune:
          final amount = min(
            review.fortuneSelection,
            _sheetRollFortune(review),
          );
          if (amount <= 0) return;
          fortuna -= amount;
          invalidateHiddenEyeDerivedCaches();
          review.fortune += amount;
          review.fortuneWasSpent = true;
          review.total += amount;
        case OculumRollRescue.pact:
          fatePactUsed = true;
          final outcome = oculumFatePactOutcome(
            negativeCritical: review.natural == 1,
            percentile: (sheetRollRescueRandom ?? Random.secure()).nextInt(100),
          );
          if (outcome == OculumFatePactOutcome.oculumChoice) {
            // Preserve the established base fallback if the choice is interrupted.
            ispirazioniController.text =
                '${leggiNumero(ispirazioniController) + 1}';
            notifyDiceResultChanged();
            await forzaSalvataggioImmediato(soloLocale: true);
            if (!mounted ||
                !identical(sheetRollReview, review) ||
                !review.isCurrent()) {
              return;
            }
            final accepts = await showDialog<bool>(
              context: context,
              builder: (dialog) => AlertDialog(
                title: Text(label),
                content: Text(
                  t(
                    'Scegli se ritirare il critico (50% positivo, 50% negativo) o ricevere un’Ispirazione base e conservare il tiro.',
                    'Choose a critical reroll (50% positive, 50% negative) or keep the roll and receive a base Inspiration.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: Text(
                      t('Ricevi Ispirazione base', 'Receive base Inspiration'),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: Text(t('Ritira come critico', 'Reroll as critical')),
                  ),
                ],
              ),
            );
            if (!identical(sheetRollReview, review) || !review.isCurrent()) {
              return;
            }
            if (accepts == true) {
              ispirazioniController.text =
                  '${max(0, leggiNumero(ispirazioniController) - 1)}';
              _replaceSheetRoll(
                review,
                _sheetRollReplacement(review, critical: true),
              );
            } else {
              keepsRoll = true;
            }
          } else {
            _replaceSheetRoll(review, _sheetRollReplacement(review));
          }
      }
      final outcomeText = _sheetRollOutcome(review);
      final detail = keepsRoll
          ? t(
              'Ispirazione base ricevuta, tiro conservato',
              'Base Inspiration received, roll retained',
            )
          : outcomeText;
      final actionNote = '$label · $detail';
      review.note = review.note.isEmpty
          ? actionNote
          : '${review.note}\n$actionNote';
      aggiungiLog('$label · ${review.label} · $detail · ${review.total}');
      programmaSalvataggio();
    } finally {
      review.busy = false;
      if (mounted && identical(sheetRollReview, review)) {
        if (!review.confirmWhenReady &&
            review.isCurrent() &&
            _sheetRollOptions(review).isNotEmpty) {
          notifyDiceResultChanged();
        } else {
          _confirmSheetRoll(review);
        }
      }
    }
  }

  String _sheetRollOutcome(_SheetRollReview review) => switch (review.natural) {
    1 => t('Critico negativo', 'Negative critical'),
    final value when value == review.faces => t(
      'Critico positivo',
      'Positive critical',
    ),
    _ => review.failed ? t('Fallito', 'Failed') : t('Riuscito', 'Succeeded'),
  };

  Widget sheetRollReviewPanel(_SheetRollReview review) {
    final options = _sheetRollOptions(review);
    final available = _sheetRollFortune(review);
    final selected = min(review.fortuneSelection, available);
    return gothicPanel(
      borderColor: review.natural == review.faces
          ? tertiaryColor
          : Colors.redAccent,
      child: Builder(
        builder: (panelContext) {
          if (!review.revealed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!panelContext.mounted ||
                  !identical(sheetRollReview, review) ||
                  review.revealed) {
                return;
              }
              review.revealed = true;
              unawaited(
                Scrollable.ensureVisible(
                  panelContext,
                  alignmentPolicy:
                      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                  duration: const Duration(milliseconds: 180),
                ),
              );
            });
          }
          return Column(
            key: const ValueKey('sheet_roll_review'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                review.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_sheetRollOutcome(review)} · ${t('Dado', 'Die')} ${review.natural} · ${t('Totale', 'Total')} ${review.total}',
              ),
              if (review.note.isNotEmpty) Text(review.note.trim()),
              if (options.contains(OculumRollRescue.fortune))
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: t('Riduci Fortuna', 'Use less Luck'),
                      onPressed: review.busy || selected <= 1
                          ? null
                          : () {
                              review.fortuneSelection = selected - 1;
                              notifyDiceResultChanged();
                            },
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '+$selected · ${t('Totale', 'Total')} ${review.total + selected}',
                    ),
                    IconButton(
                      tooltip: t('Aumenta Fortuna', 'Use more Luck'),
                      onPressed: review.busy || selected >= available
                          ? null
                          : () {
                              review.fortuneSelection = selected + 1;
                              notifyDiceResultChanged();
                            },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final choice in options)
                    OutlinedButton(
                      onPressed: review.busy
                          ? null
                          : () => _useSheetRollRescue(review, choice),
                      child: Text(switch (choice) {
                        OculumRollRescue.base when review.chainedFate =>
                          '${_sheetRollRescueLabel(choice)} ×2',
                        OculumRollRescue.fortune =>
                          '${_sheetRollRescueLabel(choice)} +$selected',
                        _ => _sheetRollRescueLabel(choice),
                      }),
                    ),
                  TextButton(
                    onPressed: review.busy
                        ? null
                        : () => _confirmSheetRoll(review),
                    child: Text(t('Conferma tiro', 'Confirm roll')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
