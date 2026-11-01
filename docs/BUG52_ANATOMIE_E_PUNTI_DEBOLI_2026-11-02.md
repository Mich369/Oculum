# Anatomie e bersagli precisi — 2 novembre 2026

Riga BUG52, richiesta: «dai disegni confermati poi rivedi anatomia e punti colpibili», con controllo dei bug probabili e meno probabili. Correzione locale verificata; CI, pacchetti e pubblicazione successivi hanno prove separate. Nessuna chiusura al 100% senza conferma dell’utente.

## Problemi riprodotti

L’esportazione dei bersagli delle 23 creature illustrate ha mostrato arti mancanti in sette famiglie. Alcuni punti deboli descritti con precisione venivano estesi a zone adiacenti: petto di Brumìlio alle ali, catena di DeadlySins alle braccia, nuclei al torace intero. Nel Golem questo lasciava il torace marcato debole anche prima di rompere le piastre, pur nascondendo correttamente il bersaglio nucleo.

Il parser delle regioni secondarie leggeva inoltre frammenti di parole: «aspetto» come petto, «mantenne» come antenne, «rancuore» come cuore, «bisacca» come sacca, «ancore» come core e «piegate» come piega. Non riconosceva invece «giunture» al plurale.

## Adattamento

- Completate le parti predefinite di DeadlySins, Rascalume, Mìrula, Colosso di Prismarite, Brumìlio, Vèndulo e Diavolo Obliterato, comprese le varianti generate. Numero degli arti e materiali seguono descrizioni e immagini canoniche; l’elmo chiuso non espone occhi.
- Il Diavolo mantiene i due occhi normali e il terzo occhio sulla fronte, distinto come bersaglio. Le due corna non aggiungono nuove capacità.
- Resi specifici i punti deboli già presenti nel catalogo: catena, vibrisse, pelle del muso, petto, nuclei, terzo occhio e molle. Il torace del Golem non aggira più le piastre. Il ventre del Goblin conserva l’ID e identifica l’innesco.
- Riconoscimento delle regioni per parole intere; conservati i veri organi e le giunture al plurale.
- Le correzioni dei punti deboli si applicano alle diciture predefinite riconosciute. Una lista anatomica esplicita salvata dal Master viene restituita prima delle deduzioni; punti deboli personalizzati restano prioritari. Nessuna nuova statistica, Skill, resistenza, immunità o quantità di drop.

## Prove locali

Il gruppo finale passa **41 test**, inclusi 12 nuovi casi sulle anatomie, un nuovo caso sul petto/nucleo del Golem, piastre/scatola, perdita Vita effettiva, bersagli pubblici, duplicati, salvataggi e priorità delle personalizzazioni. Log: `build/november-anatomy-41-passed-local.log`. I gruppi precedenti da 211 e 118 test si sovrappongono e non vanno sommati a questo conteggio. L’esportazione JSON dell’audit è un’ispezione, non un test aggiuntivo di combattimento.

Analisi statica mirata pulita in 50,4 secondi. CI finale, pacchetti e pubblicazione vengono riportati con i loro esiti effettivi nel rapporto di consegna. Queste prove non equivalgono a una nuova sessione completa su tre dispositivi fisici.

## Cosa rimane modificabile

Descrizioni, punti deboli, numero e nomi delle parti, materiale, integrità/Vita delle parti, resistenze, effetti e requisiti restano negli editor e nel JSON esistenti. Temi, reliquie, colori e trasparenze sono decorazioni selezionabili. Le 48 nuove proposte notturne non sono approvate né installate automaticamente.
