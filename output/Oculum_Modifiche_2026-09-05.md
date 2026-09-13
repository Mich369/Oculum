# Oculum — modifiche del 5 settembre 2026

## Interfaccia

- Mod Manoscritto Vivente: barra compatta, pergamena, cornici ricavate dal riferimento, elenco personaggi, azioni utilizzabili, turnistica, bersaglio e dadi.
- L’occhio è preso direttamente dall’immagine fornita, conservata integralmente in `assets/oculum/manuscript_reference.png`. Il ritaglio avviene nella vista; il file originale non viene alterato.
- La barra della mod mostra Vita in verde, Volontà in rosso, Materia in azzurro e Oculum nel colore scelto nelle impostazioni, viola come predefinito. Vita Afona nasconde anche questo valore e la relativa barra.
- Mobile con mod: risorse su due righe, personaggi scorrevoli, pannelli «Azioni e Art» e «Turno e dadi».
- Mobile classico: statistiche anticipate nel layout classico, spazi uniformi e scorciatoie fisse per Modifica, Danno/Cura, Skill, Art ed EXP.
- I collegamenti ai campi della scheda aprono la vista modificabile; «Torna a Gioca» riporta alla mod. Rimangono disponibili le funzioni originali.

## Mostri

- Pinepine: chiarito nel Book, nelle forme della sua Art e nella passiva generata che il Fuoco provoca l’esplosione della pelle e danneggia anche il Pinepine stesso, oltre alle creature entro 2 metri. Danno base dell’esplosione = Vita rimanente + Danni, calcolato una sola volta. Il comando «Esplosione Pinepine» in Danno/Cura risolve l’autodanno con le protezioni e il modificatore selezionati; il log indica il valore da risolvere separatamente sulle altre creature entro 2 metri. Usalo quando il Fuoco innesca la reazione; non viene dedotto dal tipo dei tuoi attacchi.

- Grado calcolato dal livello nel tutorial, nel Book e nella generazione rapida.
- Ogni Grado aggiunge 10 punti per un mostro comune, 15 per un Mini-Boss, 25 per un Boss.
- Presenza di Skill o Oculum Art: Resilienza e Oculum ricevono le quote principali; Volontà e Materia raggiungono soglie utili. Senza entrambe, Oculum resta a zero.
- La distribuzione usa tutti i punti, senza assegnarli nuovamente come riserva libera. Le Art vuote non contano come poteri.
- Le nuove Open comprendono un Buff Open all’attivazione e una Skill Open separata con Cooldown iniziale di 3 turni. Restano valide le condizioni esistenti di sblocco dell’Open e i costi di integrità.
- Le capacità già personalizzate conservano testi, effetti e tempi. I vecchi salvataggi mantengono le statistiche assegnate.

## Manuale

- Testi italiani rivisti, esempi coerenti con le soglie dei Gradi, nuove regole di generazione e spiegazione delle Open.
- Tutti i 24 capitoli restano presenti. PDF con testo allineato a sinistra, titoli color inchiostro e impaginazione continua: 27 pagine.

## Occhi dei Caduti, passive e prestazioni

- Gli Occhi ereditano le tecniche del mostro selezionato. Comune conserva i poteri ma non usa Art, Non Comune sblocca 1 Art, Raro 2, Oculum 3. Il Reforge rende disponibili le successive senza cancellare le personalizzazioni.
- Gli Occhi precedenti con riferimento al Monster Book recuperano le tecniche mancanti quando vengono aperti o evocati.
- Le Art del Book conservano i nomi delle tecniche originali. Nella generazione libera i nomi descrivono l’azione, senza intestazioni come «Pagina 1 — Natura».
- Le tecniche generate nascono sulla forma 0. I/II/III indicano la versione da attivare, non la forma già attiva in creazione.
- Le Skill passive rimangono sempre equipaggiate; il comando per disequipaggiarle non applica più rimozioni di bonus.
- Eliminata la conversione completa in JSON durante le copie degli Occhi: mappe e liste vengono copiate, mentre le stringhe immutabili delle immagini vengono condivise senza alterarle.
- Gli Occhi si sincronizzano solo se la scheda è cambiata. Il conteggio degli evocati viene calcolato una volta per elenco, invece che per ogni carta. La ricerca aggiorna il solo elenco.
- La pulizia dei testi ripetuti usa una cache limitata; i testi semplici evitano la conversione in sequenze di caratteri.
- Corretto un errore di layout nelle carte degli Occhi. Le informazioni lunghe restano raggiungibili scorrendo la carta; intestazioni e menu del tutorial si adattano ai telefoni stretti.
- Benchmark delle sole copie salvato in `output/performance/fallen-eye-snapshot.json`. Non è una misura degli FPS dell’intera applicazione.

## Cosa puoi modificare nell’app

- Mod attiva, modalità desktop/mobile, tema e colore Oculum.
- Nome e immagini originali delle schede, ritagli e aspetto del personaggio.
- Livello e tipo del mostro; il Grado viene ricavato automaticamente.
- Statistiche assegnate nella schermata di creazione, rispettando il totale disponibile.
- Testi, costi e forme delle Skill e delle Art.
- Nome e descrizione Open, Buff Open, Skill Open, effetti strutturati e Cooldown.
- Equipaggiamento, risorse, Sottotratti, EXP, condizioni, turni, danni e cure attraverso i comandi già presenti.

## Verifiche

- `flutter analyze`: nessun problema.
- Ultima suite completa e log delle build: `build/full-test-final.log`, `build/analyze-final.log`, `build/distribution-build-final.log` e `build/distribution-test-final.log`.
- Distribuzione dei punti verificata per tutti i budget da 0 a 5000 e per tutte le creature del Book ai livelli 0, 1, 10, 30 e 200.
- Vista Flutter controllata con test di impaginazione a 1440×900, 1100×600 e 390×844; vista classica mobile anche a 320×640. Immagini in `output/ui`.
- Tutte le pagine PDF renderizzate e controllate; questi controlli non equivalgono a una prova manuale su telefono fisico.
- Backup dei salvataggi conservato localmente in `output/checkpoints/2026-09-05-manual-mod`; escluso da qualsiasi pacchetto di codice.
- La copia PDF aggiornata è `output/pdf/Oculum_Manuale_Regole_2026-09-05.pdf`. Il nome storico viene aggiornato quando il visualizzatore Windows non lo mantiene bloccato.

## Avvio Windows su altri PC

- Incluse le DLL Microsoft Visual C++ in tutte le cartelle e negli ZIP Windows, anche Demo, Standard, latest e test.
- CMake le include nelle build future; la distribuzione si interrompe se manca una delle tre DLL essenziali.
- Aggiunte istruzioni di avvio e collegamento al runtime Microsoft ufficiale. Nessuna modifica ai salvataggi.
