# BUG51 — APK e App Bundle separati, 2 novembre 2026

La build coordinata `d3bd477e8746a6f0156352889b6069678117363a`, run41355899555, ha superato2.236test (6saltati),4prove online autenticate e tutti i9job. Il publisher successivo41360565295 è fallito prima di creare/promuovere un nuovo Release: l’archivio unico `Oculum-Android` era2.159.321.064byte, oltre il limite di2.147.483.648byte per asset GitHub.

La crescita degli artwork ha quindi superato un limite del contenitore, senza un errore nei pacchetti compilati. La distribuzione locale e il precedente canale pubblico sono rimasti conservati.

## Correzione

- `Oculum-Android` conserva il nome atteso dalle versioni precedenti dell’app e contiene soltanto APK e rapporto di compatibilità della firma.
- Il nuovo artifact separato `Oculum-Android-AAB` contiene l’App Bundle. È riconosciuto fra i download aggiuntivi del publisher e nel menu Web; non sostituisce il download APK negli aggiornamenti automatici.
- La protezione del publisher contro asset di2GiB o superiori resta attiva. Nessuna immagine, firma, salvataggio o regola di combattimento è stata cambiata per ridurre le dimensioni.
- I nuovi artifact previsti sono12, compresi Windows normale e Test e le loro cartelle distinte. La nuova compilazione e la pubblicazione saranno verificate separatamente; la sola build precedente non certifica questa correzione.

## Prove

Passati13test Python del publisher, compresa la regressione che rifiuta APK+AAB combinati oltre2GiB e accetta i due pacchetti separati. Passati11test Flutter: verificano che il menu mostri entrambi e che l’aggiornamento Android scelga ancora `Oculum-Android` anche se l’AAB appare prima nel catalogo.

L’accettazione finale della riga100% resta da chiedere all’utente con adattamento e prove della consegna effettiva.

Analisi statica mirata dei tre file Dart: nessun problema,23,2s. I23set canonici e i test di combattimento rimangono quelli della fase precedente: la correzione modifica soltanto confezione e riconoscimento dei download.
