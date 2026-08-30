part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeDicePage on _OculumHomePageState {
  void tiraDadoCustom(int facce) {
    final quantita = min(
      1000,
      max(1, int.tryParse(diceAmountController.text) ?? 1),
    );
    final modificatoreManuale = int.tryParse(diceModifierController.text) ?? 0;
    final modificatoreGlobale = tiroGlobaleBonus();
    final difficulty = difficoltaTiro();
    final modificatore =
        modificatoreManuale +
        modificatoreGlobale +
        modificatoreDifficoltaTiro();
    final tiriConCritico = <String>[];

    var totale = 0;
    var modificatoreCritico = 0;
    var criticoUno = false;
    var criticoMax = false;

    for (int i = 0; i < quantita; i++) {
      final tiro = tiraDado(facce);
      final critico = criticalDieModifier(tiro, facce);
      modificatoreCritico += critico;
      totale += tiro + critico;
      tiriConCritico.add(
        critico == 0 ? '$tiro' : '$tiro${signedRollPart(critico)}',
      );

      if (quantita == 1) {
        criticoUno = tiro == 1;
        criticoMax = tiro == facce;
      } else {
        criticoUno = criticoUno || tiro == 1;
        criticoMax = criticoMax || tiro == facce;
      }
    }

    final finale = totale + modificatore;
    final testoMod = modificatore == 0
        ? ''
        : ' ${modificatore > 0 ? '+' : ''}$modificatore';
    final testoGlobale = modificatoreGlobale == 0
        ? ''
        : ' (${t('mod. globale', 'global mod')} ${signedRollPart(modificatoreGlobale)})';
    final testoDt = difficulty == 0
        ? ''
        : ' (DT ${signedRollPart(difficulty)})';
    final testoCritico = modificatoreCritico == 0
        ? ''
        : ' ${signedRollPart(modificatoreCritico)} ${t('critico', 'critical')}';
    final formulaDadi = tiriConCritico.length == 1
        ? tiriConCritico.first
        : tiriConCritico.length <= 40
        ? tiriConCritico.join(' + ')
        : totale.toString();
    final zeroOutcome = oculumRollZeroOutcomeText(
      total: finale,
      difficulty: difficulty,
    );

    setState(() {
      dadoMostrato = '$finale$zeroOutcome';
      dadoMostratoFacce = facce;
      tiroCriticoUno = criticoUno;
      tiroCriticoVenti = criticoMax;
      risultato =
          '${t('Lancio', 'Roll')} ${quantita}d$facce: $formulaDadi$testoMod = $finale$testoCritico$testoGlobale$testoDt$zeroOutcome';
      aggiungiLog(risultato);
    });
    registerValidRoll();

    mostraDadoCentrale(
      valore: '$finale$zeroOutcome',
      criticoUno: criticoUno,
      criticoVenti: criticoMax,
      facce: facce,
    );
    sendRealtimeDiceRoll(
      label: '${quantita}d$facce',
      roll: totale,
      bonus: modificatore,
      total: finale,
    );
  }

  Widget diceSetButton(int facce, {required bool extra, bool large = false}) {
    final border = extra ? tertiaryColor : primaryColor;
    final textColor = extra ? tertiaryColor : primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => tiraDadoCustom(facce),
        child: Ink(
          decoration: BoxDecoration(
            color: secondaryColor.withValues(alpha: extra ? 0.62 : 0.48),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: border.withValues(alpha: 0.09),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Center(
            child: large
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      D20Widget(
                        text: 'd$facce',
                        fillColor: secondaryColor,
                        textColor: textColor,
                        glow: false,
                        tertiaryColor: tertiaryColor,
                        faces: facce,
                        size: 68,
                      ),
                    ],
                  )
                : Text(
                    'd$facce',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget sheetDiceButton(int facce, {required bool extra, bool dense = false}) {
    final color = extra ? tertiaryColor : primaryColor;
    final size = dense ? 64.0 : 76.0;
    final buttonGlow = !phoneCompactUi && (facce == 20 || facce == 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => tiraDadoCustom(facce),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF070910),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.62)),
          ),
          child: Center(
            child: D20Widget(
              text: 'd$facce',
              fillColor: secondaryColor,
              textColor: color,
              glow: buttonGlow,
              tertiaryColor: tertiaryColor,
              faces: facce,
              size: size,
            ),
          ),
        ),
      ),
    );
  }

  Widget compactDiceField({
    required String label,
    required TextEditingController controller,
    bool dense = false,
  }) {
    final secondaryHsl = HSLColor.fromColor(secondaryColor);
    final diceFieldFill = secondaryHsl
        .withLightness(min(0.10, secondaryHsl.lightness))
        .withSaturation(max(0.18, secondaryHsl.saturation))
        .toColor();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: tertiaryColor.withValues(alpha: 0.62),
        width: 1.2,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            cleanUiText(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tertiaryColor,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        SizedBox(height: dense ? 5 : 6),
        SizedBox(
          height: dense ? 42 : 46,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            maxLines: 1,
            onChanged: (_) => programmaSalvataggio(),
            style: TextStyle(
              color: Colors.white,
              fontSize: dense ? 17 : 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: diceFieldFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: border,
              enabledBorder: border,
              disabledBorder: border,
              errorBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: tertiaryColor, width: 1.8),
              ),
              labelStyle: TextStyle(color: tertiaryColor),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.44)),
            ),
            cursorColor: tertiaryColor,
          ),
        ),
      ],
    );
  }

  Widget sheetDiceRollControls({bool dense = false, bool showTitle = true}) {
    const classicDice = <int>[4, 6, 8, 10, 12, 20, 100];
    const extraDice = <int>[
      2,
      3,
      5,
      7,
      9,
      14,
      16,
      18,
      22,
      24,
      26,
      28,
      30,
      32,
      34,
      36,
      40,
      48,
      50,
      60,
      70,
      72,
      80,
      90,
      120,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final columns = availableWidth >= 760
            ? 7
            : availableWidth >= 560
            ? 5
            : availableWidth >= 380
            ? 4
            : 3;
        final spacing = dense ? 8.0 : 10.0;
        final rawItemWidth =
            (availableWidth - spacing * (columns - 1)) / columns;
        final itemWidth = rawItemWidth
            .clamp(dense ? 72.0 : 84.0, dense ? 104.0 : 120.0)
            .toDouble();
        final itemHeight = dense ? 88.0 : 102.0;

        Widget diceGrid(List<int> dice, {required bool extra}) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final facce in dice)
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: sheetDiceButton(facce, extra: extra, dense: dense),
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Row(
                children: [
                  Icon(Icons.casino, color: tertiaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('Dadi rapidi', 'Quick dice'),
                      style: TextStyle(
                        color: tertiaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: dense ? 16 : 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: compactDiceField(
                    label: t('Numero dadi', 'Dice amount'),
                    controller: diceAmountController,
                    dense: dense,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: compactDiceField(
                    label: t('Bonus +', 'Bonus +'),
                    controller: diceModifierController,
                    dense: dense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            rollDifficultyField(compact: true),
            const SizedBox(height: 12),
            diceGrid(classicDice, extra: false),
            const SizedBox(height: 10),
            diceGrid(extraDice, extra: true),
          ],
        );
      },
    );
  }

  Widget sheetDiceRollPanel({bool dense = false}) {
    return gothicPanel(
      borderColor: tertiaryColor,
      padding: EdgeInsets.all(dense ? 10 : 14),
      child: sheetDiceRollControls(dense: dense),
    );
  }

  Widget diceSetGrid(List<int> diceTypes, {required bool extra}) {
    final compactPhone = MediaQuery.of(context).size.shortestSide < 600;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compactPhone ? 3 : 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.42,
      ),
      itemCount: diceTypes.length,
      itemBuilder: (context, index) {
        return diceSetButton(diceTypes[index], extra: extra);
      },
    );
  }

  Widget phoneDiceDropdownSection({
    required String id,
    required String title,
    required IconData icon,
    required bool expanded,
    required ValueChanged<bool> onChanged,
    required Widget child,
    Color? color,
  }) {
    final sectionColor = color ?? primaryColor;

    return gothicPanel(
      borderColor: sectionColor,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: sectionColor.withValues(alpha: 0.08),
          highlightColor: sectionColor.withValues(alpha: 0.06),
        ),
        child: ExpansionTile(
          key: ValueKey<String>('phone_dice_$id'),
          initiallyExpanded: expanded,
          maintainState: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          iconColor: sectionColor,
          collapsedIconColor: sectionColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          onExpansionChanged: (value) {
            setState(() => onChanged(value));
          },
          leading: Icon(icon, color: sectionColor, size: 20),
          title: Text(
            cleanUiText(title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sectionColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget phoneDiceSetupPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallInfoText(
          t(
            'Scegli quanti dadi tirare e il bonus rapido da sommare.',
            'Choose how many dice to roll and the quick bonus to add.',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: compactDiceField(
                label: t('Numero dadi', 'Dice amount'),
                controller: diceAmountController,
                dense: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: compactDiceField(
                label: t('Bonus +', 'Bonus +'),
                controller: diceModifierController,
                dense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        rollDifficultyField(compact: true),
      ],
    );
  }

  Widget dicePage() {
    final compactPhone = MediaQuery.of(context).size.shortestSide < 600;

    if (compactPhone) {
      return ListView(
        key: sheetScrollKey('dice'),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        children: [
          functionAnchor(
            'dice_root',
            sectionTitle(t('Sessione Dadi', 'Dice Session')),
          ),
          diceResultPanel(),
          sheetDiceRollPanel(dense: true),
        ],
      );
    }

    return ListView(
      key: sheetScrollKey('dice'),
      padding: const EdgeInsets.all(16),
      children: [
        functionAnchor(
          'dice_root',
          sectionTitle(t('Sessione Dadi', 'Dice Session')),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final splitLayout =
                modalitaDesktop && constraints.maxWidth >= 760 ||
                constraints.maxWidth >= 940;
            if (splitLayout) {
              final resultWidth = (constraints.maxWidth * 0.28)
                  .clamp(300.0, 420.0)
                  .toDouble();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sheetDiceRollPanel()),
                  const SizedBox(width: 12),
                  SizedBox(width: resultWidth, child: diceResultPanel()),
                ],
              );
            }

            return Column(children: [diceResultPanel(), sheetDiceRollPanel()]);
          },
        ),
      ],
    );
  }
}
