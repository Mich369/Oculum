# Schivate Oculum — verifica del 24 novembre 2026

## Correzione richiesta

La scheda mostra il solo numero disponibile, senza rapporto tra disponibili e totali. Il comando Schivata nella scheda, l’indicatore rapido e il contatore della pagina risorse aprono lo stesso editor con pressione prolungata o tasto destro. Nell’editor sono presenti `+1`, `-1` e quantità disponibile scrivibile; `Salva` conferma e `Annulla` scarta. Il tocco normale sul comando della scheda apre ancora la preparazione della Schivata.

Il valore non scende sotto zero. La correzione può rimuovere anche una carica ottenuta dal Grado. `schivateOculumConsumate` resta invariato: le rimozioni manuali dei conferimenti di base sono conservate nel nuovo campo JSON `schivateOculumRimosseManualmente`, inizialmente zero per le schede precedenti. Le cariche aggiuntive continuano a usare `schivateOculumBonus`. Le tre informazioni rimangono separate, senza rigenerazioni automatiche.

Il salvataggio dell’editor verifica identità della scheda, campagna, stanza e possibilità di modifica. Se cambia uno di questi riferimenti il menu non modifica la nuova scheda. I vincoli di sola lettura e restrizione del Master impediscono la modifica.

## Personalizzazioni disponibili

- Schivate disponibili: `+1`, `-1` o quantità intera scritta nel menu, fino a zero; il valore rimane nella scheda e nel JSON esportato.
- Nome, Vita, statistiche, Grado, riserve, squadre, immagini e aspetto restano modificabili dagli editor già esistenti.
- Abilità e forme conservano requisiti, costi, durata, recuperi, bersagli, effetti, testo e Azione gratuita modificabili negli editor e nel JSON. Le personalizzazioni salvate non vengono sostituite.
- Restano modificabili quantità e dati degli oggetti e consumabili e le opzioni del Fight Creator. La regola dei nuovi nemici feriti resta quella confermata: probabilità 20%, Vita residua 25–75%.

## Stato delle verifiche

- **31 test Flutter mirati passati**: `oculum_dodge_secondary_edit_test.dart`, `oculum_resistances_turns_integrity_test.dart`, `oculum_quick_context_gestures_test.dart`, `oculum_version_log_test.dart` e `oculum_online_damage_layers_test.dart`. Log: `build/qa-dodges-20261124-final-tests.log`.
- Le prove comprendono il comando nella scheda completa a **390×844** e **1440×1000**, il tocco normale per la preparazione, pressione prolungata e clic destro sui controlli, campo numerico, `+1`, `-1`, minimo zero, annullamento, JSON precedente, ricaricamento, cariche consumate conservate e blocco dopo cambio di scheda, campagna, stanza o permesso.
- `flutter analyze --no-pub lib test`: **nessun problema**, 193,2 secondi. Log: `build/qa-dodges-20261124-analyze.log`.
- Esportatore manuale: **2 test Python passati**, tutte le 116 sezioni esportate. Registro cumulativo sincronizzato nell’asset offline.

La prima esecuzione ha individuato selettori di prova ambigui e un vecchio test senza scheda selezionata. Corretti i fixture; la verifica finale sopra è passata. Il salvataggio legge il testo effettivo del campo anche prima del ridisegno del frame, evitando di confermare un valore precedente.

## Pacchetti locali

Destinazione dedicata: `build/distribution/Oculum-App-20261124-Schivate`, con `windows/oculum.exe`, `windows-test/Oculum-Test.exe`, runtime completi, ZIP Windows separati e APK release. La procedura conserva tutte le distribuzioni precedenti e controlla che il codice non cambi durante la compilazione.

L’APK usa **versionCode 100299**, superiore alla precedente candidata locale 100298. La chiave è quella già presente e deve coincidere con il certificato stabile fissato nel progetto; nessuna nuova identità viene generata e nessun file privato viene incluso.

Il completamento dei pacchetti e il commit esatto sono attestati da `build/Oculum-App-20261124-Schivate-PACKAGES-VERIFIED.json` e `build/distribution/Oculum-App-20261124-Schivate/BUILD-VERIFICATE.json`. La firma viene verificata separatamente in `build/Oculum-App-20261124-Schivate-ANDROID-SIGNATURE.json`. L’avvio nativo di entrambi gli EXE richiede una propria ricevuta `build/native-app-smoke-*/NATIVE-BOOTSTRAP-VERIFIED.json`; usa cartelle dati vuote isolate con rete disattivata, senza aprire le campagne dell’utente. Le ricevute sono prove soltanto dopo la loro effettiva creazione e verifica.

La pubblicazione GitHub resta sospesa fino alle scelte dei lotti e dei nomi. Test locali, avvio nativo isolato, firma APK, CI e verifica dei download pubblici sono prove distinte. Nessuna modifica a `oculum_rl/`, ai salvataggi dell’utente o ai pacchetti precedenti.
