part of '../../main.dart';

extension _OculumPiovraBite on _OculumHomePageState {
  void claimPiovraBite(Map<String, dynamic> request) {
    final encounter = '${request['encounterId'] ?? ''}';
    final packet = '${request['id'] ?? ''}';
    final monster = '${request['sourceMonsterBookId'] ?? ''}';
    final receipt = request['damageReceipt'];
    final effects = request['effects'];
    if (encounter.isEmpty ||
        encounter != onlineCombatEncounterId ||
        request['scope'] != permissionScope ||
        packet.isEmpty ||
        request['status'] != 'resolved' ||
        receipt is! Map ||
        effects is! List ||
        monster.split('_variante_').first != oculumPiovraSucchiasangueId) {
      return;
    }
    final effect = effects
        .whereType<Map>()
        .where(
          (effect) =>
              effect['type'] == 'planar' &&
              effect['target'] == oculumPiovraBiteDrain,
        )
        .firstOrNull;
    if (effect == null || _friendlyFireFor(request).friendly) return;
    final healing = oculumPiovraGripHealing(
      readIntValue(receipt['hpLost']),
      percent: readIntValue(effect['valueExpression']),
    );
    if (healing == 0) return;
    faunaForOwnedSheet('${request['sourceTag'] ?? ''}', () {
      if (hpCorrenti() <= 0 ||
          !faunaReceipt('piovra-bite:$encounter:$packet')) {
        return;
      }
      final before = hpCorrenti();
      applyStructuredHealing('vita', healing);
      final restored = hpCorrenti() - before;
      if (restored > 0) {
        aggiungiLog('[MORSO SUCCHIASANGUE] Recuperati $restored punti Vita.');
        sendRealtimeHpChanged();
        notifyActiveSheetSummaryChanged();
      }
      programmaSalvataggio();
    });
  }
}
