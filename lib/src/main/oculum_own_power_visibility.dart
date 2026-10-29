part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumOwnPowerVisibility on _OculumHomePageState {
  bool get canSetOwnPowerVisibility =>
      schedaCorrente >= 0 &&
      schedaCorrente < schedePersonaggio.length &&
      schedePersonaggio[schedaCorrente]['realtimeSharedSheet'] != true;

  bool get showOwnTotalPower {
    final explicit = planarState['showOwnTotalPower'];
    if (explicit is bool) return explicit;
    final legacy = knownPowerFor(sheetTagAt(schedaCorrente));
    return legacy['exactPower'] is num ||
        legacy['scannerEstimate'] is num ||
        oculumPowerReadPhrases.containsKey('${legacy['powerBand'] ?? ''}');
  }

  void setShowOwnTotalPower(bool value) {
    if (!canSetOwnPowerVisibility) return;
    setState(() => planarState['showOwnTotalPower'] = value);
    // Presentation preference only: never write discovery records or publish
    // an observation that would reveal another participant's power.
    programmaSalvataggio(invalidateCaches: false);
  }

  int? powerBadgeOverride(String tag) {
    final index = localSheetIndexForOculumTag(tag);
    if (haPermessiMaster) {
      if (index >= 0) return scoutTotalPowerAt(index);
      final token = onlineCombatTokens()
          .where((t) => combatTokenMatchesSheet(t, tag))
          .firstOrNull;
      return token == null ? null : oculumTokenDisplayTotalPower(token);
    }
    final own = oculumSameSheetIdentity(tag, sheetTagAt(schedaCorrente));
    return own &&
            canSetOwnPowerVisibility &&
            planarState['showOwnTotalPower'] == true
        ? scoutTotalPowerAt(schedaCorrente)
        : null;
  }

  bool hideOwnPowerBadge(String tag) =>
      !haPermessiMaster &&
      canSetOwnPowerVisibility &&
      oculumSameSheetIdentity(tag, sheetTagAt(schedaCorrente)) &&
      planarState['showOwnTotalPower'] == false;

  Widget ownPowerVisibilitySetting() => SwitchListTile(
    value: showOwnTotalPower,
    activeThumbColor: tertiaryColor,
    title: Text(t('Mostra la mia Potenza Totale', 'Show my Total Power')),
    subtitle: Text(
      t(
        'Solo ${nomeSchedaPersonaggio(schedaCorrente)}: mostra la tua PT sotto il nome. Ogni scheda conserva la propria scelta. Il Master vede comunque tutte le PT.',
        'Only ${nomeSchedaPersonaggio(schedaCorrente)}: show your PT below the name. Each sheet retains its own choice. The Master can still see all PT values.',
      ),
    ),
    onChanged: canSetOwnPowerVisibility ? setShowOwnTotalPower : null,
  );

  ({int total, int known, int unknown}) masterPartyDisplayPower() {
    var total = 0, known = 0, unknown = 0;
    final seen = <String>{};
    for (final index in partyStatsCountIndexes()) {
      final tag = sheetTagAt(index);
      if (!seen.add(normalizeOculumFriendTag(tag))) continue;
      final sheet = schedePersonaggio[index];
      final hasCores = const ['resilienza', 'volonta', 'materia', 'oculum']
          .every(
            (key) => sheet[key] is num || int.tryParse('${sheet[key]}') != null,
          );
      final value = hasCores
          ? scoutTotalPowerAt(index)
          : oculumTokenDisplayTotalPower(sheet);
      if (value == null) {
        unknown++;
        continue;
      }
      total += value;
      known++;
    }
    return (total: total, known: known, unknown: unknown);
  }

  Widget masterPartyPowerSummary() {
    if (!haPermessiMaster) return const SizedBox.shrink();
    final power = masterPartyDisplayPower();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'PT totale party: ${power.total}${power.unknown > 0 ? ' · parziale (${power.unknown} senza valori disponibili)' : ''} · ${power.known} membri calcolati',
        style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

extension OculumOwnPowerVisibilityProbe on OculumPerformanceProbe {
  bool get ownPowerVisible => _state.showOwnTotalPower;
  void showOwnPower(bool value) => _state.setShowOwnTotalPower(value);
  Widget ownPowerSetting() => _state.ownPowerVisibilitySetting();
  Future<void> switchOwnedSheet(int index) =>
      _state.cambiaSchedaPersonaggio(index);
  ({int total, int known, int unknown}) partyDisplayPower() =>
      _state.masterPartyDisplayPower();
  Widget partyDisplayPowerSummary() => _state.masterPartyPowerSummary();
}
