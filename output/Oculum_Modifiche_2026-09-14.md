# Oculum — correzione Vita Afona, 14 settembre 2026

Il riquadro HP con l'indicatore delle condizioni ora rispetta Vita Afona:
`10/40` diventa `???/40`. Il massimale resta visibile, come richiesto.
La lettura degli HP passa dalla stessa protezione usata dalla scheda.
Anche barra vita, riepilogo compatto e Manuscript usano `???/massimale`.
Le protezioni delle barre e dei controlli già presenti restano attive.

Gli HP reali, gli effetti delle condizioni, le regole e il formato dei
salvataggi non sono stati modificati da questa correzione. Nessuna funzione
è stata intenzionalmente rimossa.

## Verifica

- Test del componente reale: HP 10/40 prima della condizione, ???/40 durante
  Vita Afona, ritorno a 10/40 dopo la rimozione; valore interno sempre 10.
- 54 test mirati superati: riquadro HP, condizioni, priorità dei titoli Open,
  copie JSON e integrità delle immagini nella cache.
- Test eseguiti con preferenze simulate e directory di prova separata;
  nessun salvataggio personale è stato usato.
- Analisi statica: nessun problema rilevato.
- Build release Windows e Android riuscite; 8 artefatti principali confrontati
  con gli output di compilazione. ZIP integri, DLL Visual C++ incluse.
- Completate anche Web e le build di prova Windows/Android: verifica finale
  superata su 12 artefatti, immagini di riferimento identiche agli originali,
  copie Windows sincronizzate e profilo di prova distinto da quello normale.

## File della correzione

- `lib/src/main/oculum_home_quick_conditions.dart`: lettura HP protetta.
- `lib/src/main/oculum_home_sheet_page.dart`: formato ???/massimale.
- `lib/src/main/oculum_performance_probe.dart`: accesso al componente per il test.
- `test/oculum_vita_afona_hp_tile_test.dart`: regressione automatizzata.
- `scripts/build_distribution_oculum.ps1`: il controllo preventivo dei processi
  aperti copre anche le sottocartelle e gli eseguibili rinominati, prima della
  pulizia. Verificato con un processo di prova simulato.

Il packaging standard si è interrotto su una DLL della versione di prova in uso.
I suoi file runtime rimossi durante il tentativo sono stati ripristinati dalla
ZIP originale; nessun salvataggio è stato coinvolto. I pacchetti principali
sono stati recuperati con compilazione e copia dirette, senza chiudere processi.

La correzione non costituisce una certificazione di completamento dell'intera
ottimizzazione prestazionale richiesta in precedenza. I benchmark disponibili
in `output/performance` sono misure del banco di prova Flutter, non frame time
GPU misurati su desktop o telefono reali.
