# Consegna verificata — build `236cd16c`

Commit compilato: `236cd16ca7321d48dacff46de93dc9b230f5fdf2`. [CI 41108738911](https://github.com/Mich369/Oculum/actions/runs/41108738911), pubblicazione 41116711589 e Pages 41116711425 riuscite.

## App e verifiche

- Correzioni di Nuvola in bottiglia, scatola del Costrutto Minore, anatomie e bersagli; quattro Armadilli e Mezzo Demone Massiccio separato; ulteriori pack già approvati. Dettagli e limiti in [rapporto della patch](PATCH_2026-10-30_NUVOLA_CORAZZE.md).
- 185 test locali mirati e analisi senza problemi; CI completa: 1.907 passati, 6 saltati. Quattro prove autenticate eseguite separatamente in CI. I conteggi locali/CI si sovrappongono e non vanno sommati.
- Installati e ricontrollati 16364 file, compreso il manifest, zero differenze. `build/distribution` contiene EXE con runtime completo, ZIP e APK; Windows normale e Test restano separati. Distribuzione precedente conservata nel backup.
- Undici download pubblici provati senza login; index, bootstrap e codice web compilato corrispondono al commit. L’accessibilità pubblica non sostituisce il confronto d’integrità dei pacchetti locali, eseguito separatamente.
- APK firmato, pacchetto `com.mich.oculum`, versionCode 100258, stessa identità della firma prevista. L’aggiornamento da vecchi APK firmati con certificati diversi resta incompatibile con l’aggiornamento diretto.
- Avvio normale e Test rimasti attivi 8 secondi; backup verificato di 61 file di salvataggio prima della prova. Chiusi soltanto i processi avviati dal test; nessun ripristino o sovrascrittura dei dati. Questa prova non è una verifica dei controlli grafici né una sessione su tre dispositivi fisici.
- Il recupero locale ha conservato i dati già scaricati dopo errori temporanei DNS/URL; hash completi e manifest sono stati verificati prima della sostituzione.

## Proposte da valutare

[Galleria locale A–E](../output/artwork/proposte_cinque_2026-10-30/GALLERIA.html): 90 scelte per 18 specie, 4 già approvate e 86 da valutare. Sei derivati di Custode/Mammuth/Armadillo attendono conferma separata. I nuovi disegni restano in output e non sostituiscono automaticamente gli asset del gioco.

Originali, prompt e SHA conservati; 16 documenti di domande. Il controllo locale comprende 1.432 collegamenti e 43 ancore senza errori. Corretta anche l’identificazione dei cinque gruppi che usavano il titolo della singola proposta al posto del nome del mostro; fixture dei formati vecchi e nuovi passate.

## Personalizzazioni e lavoro distinto

Costi, cooldown, durate, forme, probabilità, bersagli, statistiche, integrità delle parti, materiali ed effetti restano modificabili negli editor e nel JSON; conservati gli override del Master e le definizioni personali. Per gli artwork si possono scegliere e correggere sagoma, posa, espressione, inquadratura e palette compatibili con i dettagli canonici.

La migrazione delle vecchie Art personalizzate e l’integrazione delle specie illustrate non ancora presenti nel catalogo restano lavori distinti: le approvazioni dei disegni non li certificano. Nessuna riga del registro è stata chiusa al 100% senza la conferma richiesta dell’utente.

Prove locali dettagliate: `build/DELIVERY-VERIFIED-236cd16c.json`, `build/public-release-verified-236cd16c.json`, `build/android-signing-41108738911.json`, `build/startup-smoke-41108738911.json`, `output/artwork/proposte_cinque_2026-10-30/qa_consolidamento_notturno.json`.
