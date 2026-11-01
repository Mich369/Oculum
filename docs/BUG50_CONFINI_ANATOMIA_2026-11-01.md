# BUG50 — confini delle parole anatomiche

Nuovo intervento successivo alla consegna approvata f86951cb. Le righe ART45, ART46, BUG49 e QA45 restano concluse nel loro perimetro; questa correzione non è ancora nei relativi pacchetti.

## Causa ed effetto

Durante la preparazione del Goblin Kamikaze, il suo punto debole «da cui partono le micce» assegnava erroneamente vulnerabilità anche alle braccia: `arto` combaciava dentro `partono`. La stessa ricerca trovava `mano` dentro `umano` e `manopola`. Un secondo ramo trovava `ala` dentro `palato`, creando ali non descritte o rendendo deboli quelle reali quando il punto debole era nella bocca.

Il riconoscimento ora usa parole intere per i termini delle braccia e delle ali. Restano riconosciuti ala/ali/alare/alari e i termini anatomici già supportati. Non cambia la procedura per colpire, i costi, i Danni, le statistiche o gli organi salvati esplicitamente dal Master. Non vengono inventate nuove debolezze per il Goblin.

## Verifiche locali completate

- Tre regressioni hanno riprodotto gli errori prima della modifica: `build/anatomy-keyword-before-fix.log`.
- Dopo la correzione: **13 test passati** su riconoscimento delle parole, anatomie fisiche e catalogo del30ottobre; `build/anatomy-keyword-after-fix.log`.
- Controlli positivi sui veri termini anatomici e sulle ali autentiche: nessuna soppressione del loro riconoscimento.
- Le regressioni esistenti conservano le anatomie/classificazioni personalizzate e i conteggi canonici di Meccanio/FireShield.
- Analisi statica dei due file senza problemi, **26,2 secondi**: `build/anatomy-keyword-analyze.log`.
- Usato `--no-test-assets` per questi test di dati: nessun confronto grafico o caricamento del nuovo artwork nell’app implicito.

## File e stato

Modificati `lib/pages/oculum_dungeon/monster_anatomy.dart` e il nuovo `test/oculum_anatomy_keyword_boundaries_test.dart`. Sono modifiche locali per la prossima patch: **nessuna nuova CI, pubblicazione o sostituzione di EXE/ZIP/APK ancora dichiarata**. La distribuzione verificata f86951cb e il suo backup rimangono conservati.

Parti colpibili, nomi e stato debole restano personalizzabili negli editor e nel JSON; gli override espliciti precedono il riconoscimento del catalogo. Nessuna chiusura al100% senza la conferma richiesta dal registro.
