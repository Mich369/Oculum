part of '../../main.dart';

double oculumWillKingdomWeight(double capacity, double otherWeight) =>
    min(max(0.0, capacity) * .25, max(0.0, capacity - otherWeight));

int oculumWillKingdomValue(
  int value,
  double kilograms, {
  bool subtrait = false,
}) => value <= 0
    ? value
    : (value * (1 + max(0.0, kilograms) / (subtrait ? 20000 : 10000))).floor();

extension _OculumWillInventory on _OculumHomePageState {
  bool get willKingdomActive => planarState['willKingdomActive'] == true;
  double get willKingdomWeight => !willKingdomActive
      ? 0
      : oculumWillKingdomWeight(
          pesoMassimo(),
          inventario.fold<double>(
            0,
            (sum, item) => sum + item.peso * item.quantita,
          ),
        );
  int applyWillKingdomBonus(int value, {bool subtrait = false}) =>
      !willKingdomActive
      ? value
      : oculumWillKingdomValue(value, willKingdomWeight, subtrait: subtrait);

  bool toggleWillKingdom() {
    if (!willKingdomActive && volontaTotale() < 500) return false;
    planarState['willKingdomActive'] = !willKingdomActive;
    invalidateDerivedDataCaches();
    aggiungiLog(
      willKingdomActive
          ? '[REGNO DI VOLONTÀ] Creato: ${willKingdomWeight.toStringAsFixed(1)} kg riservati; +${(willKingdomWeight / 100).toStringAsFixed(3)}% Danni/Difesa e metà ai sottotratti. Nessun bonus alle statistiche.'
          : '[REGNO DI VOLONTÀ] Distrutto: spazio liberato e bonus rimossi.',
    );
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    return true;
  }

  Widget willKingdomPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      smallInfoText(
        'L’inventario è uno spazio generato dalla tua Volontà: una stanzetta a 15, una stanza crescente da 25 e un regno creabile da 500. La capacità resta Volontà ×3 kg.',
      ),
      if (volontaTotale() >= 500 || willKingdomActive)
        OutlinedButton.icon(
          onPressed: () {
            if (toggleWillKingdom()) updateOculumHomeUi(() {});
          },
          icon: Icon(
            willKingdomActive ? Icons.delete_outline : Icons.castle_outlined,
          ),
          label: Text(
            willKingdomActive
                ? 'Distruggi regno · ${willKingdomWeight.toStringAsFixed(1)} kg'
                : 'Crea regno di Volontà',
          ),
        ),
      if (willKingdomActive)
        smallInfoText(
          'Regno: +${(willKingdomWeight / 100).toStringAsFixed(3)}% Danni/Difesa; +${(willKingdomWeight / 200).toStringAsFixed(3)}% sottotratti. Occupa il 25% della capacità o lo spazio libero se inferiore. Bonus attivi finché esiste.',
        ),
    ],
  );
}
