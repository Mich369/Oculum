part of '../../main.dart';

// Largest integer that can travel without rounding through every client and JSON.
final _oculumMaxDodgeInt = BigInt.from(9007199254740991);

const _dodgePaper = Color(0xFFF3DFC8);
const _dodgeCopper = Color(0xFFE4AA79);
const _dodgeInk = Color(0xFF1B141C);
const _dodgeBorder = Color(0xFF815B58);

extension _OculumDodgeDialogFlow on _OculumHomePageState {
  ({String sheet, String campaign, String scope}) get _dodgeSheet => (
    sheet: sheetTagAt(schedaCorrente),
    campaign: activeCampaignId,
    scope: permissionScope,
  );

  void _dodgeNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<T?> _openDodgeDialog<T>(WidgetBuilder builder) async {
    if (_oculumDodgeDialogOpen || !puoModificareSchivateOculum) return null;
    _oculumDodgeDialogOpen = true;
    try {
      return await oculumShowDialogUntilClosed<T>(
        context: context,
        builder: builder,
      );
    } finally {
      _oculumDodgeDialogOpen = false;
    }
  }

  bool _dodgeSheetStillCurrent(
    ({String sheet, String campaign, String scope}) origin,
  ) {
    if (!mounted) return false;
    if (puoModificareSchivateOculum && _dodgeSheet == origin) return true;
    _dodgeNotice(
      t(
        'La scheda attiva o i suoi permessi sono cambiati.',
        'The active sheet or its permissions changed.',
      ),
    );
    return false;
  }

  Future<void> modificaSchivateOculumDaTastiera() async {
    if (!puoModificareSchivateOculum || _oculumDodgeDialogOpen) return;
    final origin = _dodgeSheet;
    final available = schivateOculumDisponibili();
    final spent = schivateOculumConsumate;
    final name = nomeController.text.trim();
    final staleBalance = t(
      'Le Schivate sono cambiate. Riapri il menu per correggerle.',
      'The dodge count changed. Reopen the menu to edit it.',
    );
    bool balanceChanged() =>
        available != schivateOculumDisponibili() ||
        spent != schivateOculumConsumate;
    final value = await _openDodgeDialog<int>(
      (_) => _DodgeAmountDialog(
        initialAmount: available,
        maxAmount: max(0, _oculumMaxDodgeInt.toInt() - spent),
        sheetName: name,
        title: t('Schivate Oculum', 'Oculum Dodges'),
        amountLabel: t('Quantità disponibile', 'Available amount'),
        decrementLabel: t('Togli una Schivata', 'Remove one dodge'),
        incrementLabel: t('Aggiungi una Schivata', 'Add one dodge'),
        invalidLabel: t('Quantità fuori intervallo.', 'Amount out of range.'),
        cancelLabel: t('Annulla', 'Cancel'),
        saveLabel: t('Salva', 'Save'),
        validateSave: () {
          if (!mounted ||
              !puoModificareSchivateOculum ||
              _dodgeSheet != origin) {
            return t(
              'La scheda attiva o i suoi permessi sono cambiati.',
              'The active sheet or its permissions changed.',
            );
          }
          return balanceChanged() ? staleBalance : null;
        },
      ),
    );
    if (value == null || !_dodgeSheetStillCurrent(origin) || value == available) {
      return;
    }
    if (balanceChanged()) {
      _dodgeNotice(staleBalance);
      return;
    }
    if (!impostaSchivateOculumDisponibili(value)) {
      _dodgeNotice(
        t(
          'Quantità di Schivate fuori intervallo.',
          'Dodge amount out of range.',
        ),
      );
    }
  }
}

class _DodgeAmountDialog extends StatefulWidget {
  const _DodgeAmountDialog({
    required this.initialAmount,
    required this.maxAmount,
    required this.sheetName,
    required this.title,
    required this.amountLabel,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.invalidLabel,
    required this.cancelLabel,
    required this.saveLabel,
    required this.validateSave,
  });

  final int initialAmount;
  final int maxAmount;
  final String sheetName;
  final String title;
  final String amountLabel;
  final String decrementLabel;
  final String incrementLabel;
  final String invalidLabel;
  final String cancelLabel;
  final String saveLabel;
  final String? Function() validateSave;

  @override
  State<_DodgeAmountDialog> createState() => _DodgeAmountDialogState();
}

class _DodgeAmountDialogState extends State<_DodgeAmountDialog> {
  late final _amount = TextEditingController(text: '${widget.initialAmount}');
  bool _submitted = false;
  String? _staleMessage;

  int? get _validAmount {
    final value = int.tryParse(_amount.text);
    return value != null && value >= 0 && value <= widget.maxAmount
        ? value
        : null;
  }

  void _close(int? value) {
    if (_submitted || ModalRoute.of(context)?.isCurrent != true) return;
    _submitted = true;
    Navigator.pop(context, value);
  }

  void _save() {
    final value = _validAmount;
    if (value == null || _staleMessage != null || _submitted) return;
    final message = widget.validateSave();
    if (message != null) {
      setState(() => _staleMessage = message);
      return;
    }
    _close(value);
  }

  void _adjust(int delta) {
    final current = _validAmount ?? (_amount.text.isEmpty ? 0 : null);
    if (current == null || (delta > 0 && current >= widget.maxAmount)) return;
    final text = '${max(0, current + delta)}';
    setState(() {
      _amount.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = _validAmount;
    Widget step({
      required int delta,
      required String label,
      required bool enabled,
    }) {
      return Tooltip(
        message: label,
        child: OutlinedButton(
          key: ValueKey(delta < 0 ? 'dodge-minus-one' : 'dodge-plus-one'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 54),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: _dodgePaper,
            backgroundColor: const Color(0xFF312431),
            side: const BorderSide(color: _dodgeBorder),
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
          onPressed: enabled ? () => _adjust(delta) : null,
          child: Text(delta < 0 ? '-1' : '+1'),
        ),
      );
    }

    return _OculumDodgeDialog(
      title: widget.title,
      subtitle: widget.sheetName,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.amountLabel,
            style: const TextStyle(
              color: _dodgePaper,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              step(
                delta: -1,
                label: widget.decrementLabel,
                enabled: (amount ?? 0) > 0,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: widget.amountLabel,
                  child: TextField(
                    key: const ValueKey('dodge-available-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    inputFormatters: oculumNonNegativeIntegerFormatters,
                    style: const TextStyle(
                      color: _dodgePaper,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: _dodgePaper.withValues(alpha: .5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF110E15),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: _dodgeBorder),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: _dodgeCopper, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              step(
                delta: 1,
                label: widget.incrementLabel,
                enabled:
                    (_amount.text.isEmpty || amount != null) &&
                    (amount ?? 0) < widget.maxAmount,
              ),
            ],
          ),
          if (_staleMessage != null ||
              (_amount.text.isNotEmpty && amount == null))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _staleMessage ?? widget.invalidLabel,
                  style: const TextStyle(color: Color(0xFFFFBAAD)),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: _dodgePaper),
          onPressed: () => _close(null),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _dodgeCopper,
            foregroundColor: const Color(0xFF211419),
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
          onPressed: amount == null || _staleMessage != null ? null : _save,
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}

class _OculumDodgeDialog extends StatelessWidget {
  const _OculumDodgeDialog({
    required this.title,
    required this.subtitle,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    constraints: const BoxConstraints(minWidth: 386, maxWidth: 432),
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    backgroundColor: _dodgeInk,
    surfaceTintColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
    shape: const BeveledRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      side: BorderSide(color: _dodgeBorder),
    ),
    titlePadding: EdgeInsets.zero,
    contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 86,
          child: CustomPaint(painter: _DodgeInkSeal()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Copperplate Gothic Light',
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: _dodgePaper,
            ),
          ),
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 0),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: _dodgeCopper),
            ),
          ),
      ],
    ),
    content: content,
    actions: actions,
  );
}

/// Matte ink shapes, engraved hatching and a copper eye. Paint is confined to
/// the banner so it never sits behind text or takes pointer events.
class _DodgeInkSeal extends CustomPainter {
  const _DodgeInkSeal();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    void filling(Path path, Color color) =>
        canvas.drawPath(path, paint..color = color);
    void facet(List<Offset> vertices, Color color) {
      filling(Path()..addPolygon(vertices, true), color);
    }

    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xFF251A27));
    facet([
      Offset.zero,
      Offset(w * .67, 0),
      Offset(w * .38, h),
      Offset(0, h),
    ], const Color(0xFF3C2633));
    facet([
      Offset(w, 3),
      Offset(w, h),
      Offset(w * .53, h),
      Offset(w * .72, h * .56),
    ], const Color(0xFF492B37));
    facet([
      Offset(0, h * .56),
      Offset(w * .36, h * .17),
      Offset(w * .25, h * .54),
      Offset(0, h),
    ], const Color(0xFF120F16));
    facet([
      Offset(w * .82, 0),
      Offset(w, 0),
      Offset(w, h * .3),
      Offset(w * .64, h * .71),
    ], const Color(0xFF17121A));
    for (var i = 0; i < 7; i++) {
      final x = (i - 1) * 8.0;
      paint
        ..color = const Color(0xFF89575C)
        ..strokeWidth = i % 3 == 0 ? 1.6 : .75;
      canvas.drawLine(
        Offset(x, h - 11),
        Offset(x + 23, h - 32 - i * 1.7),
        paint,
      );
      canvas.drawLine(
        Offset(w - x, 12),
        Offset(w - x - 31, 32 + i * 1.5),
        paint,
      );
    }
    canvas.save();
    canvas.translate(w / 2, h * .49);
    final eye = Path()
      ..moveTo(-47, 3)
      ..quadraticBezierTo(-26, -10, -14, -19)
      ..quadraticBezierTo(11, -31, 48, -4)
      ..quadraticBezierTo(23, 16, 7, 21)
      ..quadraticBezierTo(-14, 27, -47, 3)
      ..close();
    canvas.drawCircle(Offset.zero, 30, paint..color = const Color(0xFF160F17));
    canvas.drawCircle(Offset.zero, 27, paint..color = const Color(0xFF67404B));
    canvas.drawPath(
      eye,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFF110C12),
    );
    paint.style = PaintingStyle.fill;
    filling(eye, const Color(0xFFB77358));
    facet(const [
      Offset(-36, 3),
      Offset(-11, -13),
      Offset(14, -17),
      Offset(36, -7),
      Offset(-2, 7),
    ], const Color(0xFFF1BD8F));
    facet(const [
      Offset(-1, -20),
      Offset(10, -2),
      Offset(2, 17),
      Offset(-7, 2),
    ], const Color(0xFF180F17));
    canvas.drawCircle(const Offset(-11, -7), 2.2, paint..color = _dodgePaper);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DodgeInkSeal oldDelegate) => false;
}
