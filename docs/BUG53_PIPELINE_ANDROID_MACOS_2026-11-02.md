# Firma Android e limite macOS — 2 novembre 2026

Righe BUG53/BUG54: migliorare l’affidabilità della consegna, mantenendo firma, immagini e aggiornamenti. Nessuna modifica alle regole del gioco o ai dati personali. Implementazione CI in verifica, nessuna chiusura100% implicita.

## Fatti verificati

Il commit applicativo bc4811b7 passa2.250test/6saltati e4prove online autenticate. Nel run41364016022 tutti gli altri job coordinati riescono, ma Android fallisce due volte in `:app:signReleaseBundle`: APK compilato e firma APK verificata; App Bundle non completato. Nessuna nuova distribuzione è stata promossa o installata.

Le due diagnosi isolate41370215757 e41371513313 usano lo stesso codice applicativo, Flutter3.47.9, Java17 e il certificato stabile. Entrambe producono APK1146,2MB e AAB1109,4MB; `jarsigner` verifica i bundle. La seconda include la copia intermedia dell’APK e i confini degli step. I runner hanno16GBRAM, oltre60GBliberi e la stessa immagine Ubuntu24.04/20261025.353.1 dei job precedenti. La causa iniziale non è quindi dimostrata come esaurimento del disco o cambio del sistema; il problema non è stato riprodotto nelle due diagnosi. Le tracce sono conservate, il workflow diagnostico temporaneo rimosso. La CI finale della pipeline rafforzata resta una prova separata.

## Modifiche da verificare nella consegna

- APK e AAB vengono costruiti nello stesso ambiente di firma, prima delle copie per la distribuzione. Entrambi devono riuscire prima degli upload. L’APK mantiene il controllo obbligatorio di fingerprint, package e versione; il bundle ha anche la verifica `jarsigner`.
- Il solo runner Android configura Gradle con heap massimo6GB e due worker; il limite locale del progetto resta3GB. Non viene cambiata la chiave. La priorità del file Gradle nella home del runner è documentata da [Gradle](https://docs.gradle.org/current/userguide/build_environment.html); Android descrive il dimensionamento della memoria nel [manuale di build](https://developer.android.com/build/optimize-your-build). È un rafforzamento delle risorse CI, non una causa già provata del primo errore.
- Se il bundle fallisce, viene conservato l’esito non riuscito e prodotta la traccia Gradle. Una ripetizione diagnostica non rende verde il comando originale fallito.
- Il workflow macOS indipendente41364016059 è stato interrotto a45minuti durante i test. La nuova configurazione conserva l’intera suite, limita la concorrenza a2e consente90minuti per test e pacchetto. Il pacchetto macOS coordinato di bc4811b7 era già riuscito; i due workflow restano prove distinte.

Il test di contratto del publisher ora controlla anche l’ordine build→firma→confezionamento e la propagazione degli errori;14casi passati,34test Python complessivi dell’aggiornamento. YAML e sei script Bash verificati;4test del log cumulativo passati e analisi del manuale pulita37,2s. Queste prove non sostituiscono la compilazione e le firme reali. Il rapporto finale riporta esclusivamente CI, pacchetti, download anonimi e avvii effettivamente completati.
