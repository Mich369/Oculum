# Patch del 28 ottobre 2026 — verifiche e personalizzazione

## Evidenze locali

- Suite completa sullo stato iniziale della patch:1.332 passati,6 saltati,5 falliti; log `build/oct28-full-regression.log`. Cinque anomalie corrette e rieseguite nei gruppi mirati: test provider Grofix, identità Senka, fixture pari PT del duello.
- Gruppo finale di13 file:49 test passati; una fixture su obiettivo personalizzato corretta, un percorso test inesistente corretto nel comando. Log `build/oct28-precommit-regression.log`. Non è dichiarata come run totalmente verde.
- Ultima run requisiti/log/fight condivisi:23/23 passati, `build/oct28-final-unlocks-and-shared.log`; include la fixture corretta dell’obiettivo personalizzato.
- Duello riuscito del risolutore di produzione: SenkaLv12 con maschera attiva e LusierIII entrambi298 PT. Originale SenkaLv1 preservata. [Scenario e limiti](personaggi/SIMULAZIONE_SENKA_LUSIER.md), [traccia JSON](../output/simulation/Senka_Lv12_vs_Lusier_III.json). Non rappresenta un tasso di vittoria né tre sessioni grafiche online indipendenti.
- Analisi statica finale: **nessun problema trovato**, `build/oct28-release-analyze.log` (131s). CI autenticata, pacchetti e download pubblici sono verifiche distinte: riportare soltanto i risultati effettivi nelle conclusioni di consegna.

## Correzioni emerse nella revisione separata

Danno realmente nullo per l’intangibilità e relativo ACK; coordinazione Veterano su esito remoto; pubblicazione delle restrizioni e dei valori zero dei cloni; riapertura delle Open consumate dalla pagina Titoli; preflight del Passo nell’Ombra prima del pagamento; bonus lunari sui valori effettivi e fine a conclusione fight; runtime dei Solari con mappa dinamica; conservazione di sottotratti e forme delle Skill negli Occhi. Le ricevute impediscono i doppi effetti dopo reinvio e caricamento.

## Cosa rimane personalizzabile

- Schede: nome, background, note, legami, statistiche, sottotratti, livello/Grado ed equipaggiamenti negli editor esistenti.
- Skill e Art: forme, requisiti di crescita, costi leggibili, risorsa, minimi/massimi, cooldown, durata, bersagli, elemento ed effetti strutturati conservati nel JSON.
- Titoli: descrizioni, bonus, punti ciechi, Skill/Open e relativi effetti. Il requisito canonico del Ricordo è in `planarRuntime.authoredTitleRequirements`, distinto dai testi narrativi e conservato se personalizzato.
- Materiali: distinguere requisiti `collect`, `possess`, `consume`, quantità e ricevuta di consumo; la raccolta storica rimane valida dopo uso o vendita.
- Requisiti Senka: FusioneVelo13; MilleTagliRiflessi9 più ErikI, senza livello minimo. Tolleranza generale25 PT; eccezione nominale Erik. Non considerare buff temporanei o la maschera come progresso permanente.
- Artwork e temi: asset/versioni/provenienza documentati. [Inventario delle creature](TEMI_CREATURE_DA_COMPLETARE.md). Le due reliquie delle Guardie sono approvate; il catalogo intero non è completato da questa patch.

## Distinzioni e arretrato

Le app reali su dispositivi separati richiedono una prova distinta dai test di trasporto. Le grandi aggiunte restano nel [registro attività](DA_FARE_PATCH_E_SUCCESSIVI.md). Non recuperare inventando sottotratti personalizzati che un vecchio Occhio abbia già perso senza conservarne lo snapshot originale. Senka non esporta il segreto di Haniel nelle proprie note.

## Ultima regressione sui cloni

Corretto il controllo del Mantello copiato: il clone con forma attiva evita un vero pacchetto fisico anche senza item maschera; attacchi spirituali e fine durata restano validi, senza passiva gratuita sulla maschera assente. Gruppo conclusivo14/14 test locali passati in `build/oct28-final-clone-shadow.log`, compresi Passo nell’Ombra copiato offensivo/difensivo, annullamento senza pagamento e log di versione. La prima fixture non registrava il clone nel roster effettivamente usato dal risolutore: corretta e rieseguita. Il commit precedente34746826 ha superato su GitHub1.340 test,6 saltati e4 verifiche online; la correzione finale richiede la propria build verificata.

## CI finale del sorgente distribuito

Commit `bb7e021b3ef0e2cf6dabf1c72083c04ea7b6b7dc`, [run40698070349](https://github.com/Mich369/Oculum/actions/runs/40698070349): analisi statica senza problemi, **1.341 test passati e6 saltati**, poi **4 test online autenticati passati**. Il job Analyze and test è riuscito; i pacchetti di piattaforma e i download sono un passaggio successivo e vengono attestati separatamente nel rapporto di consegna. Log locale del job `build/oct28-final-github-validate.log`. Non sommare le riesecuzioni mirate come se fossero test distinti.

## Correzioni successive alla sessione — verifica locale

- Fuga: causa riprodotta con clic sui pulsanti dei fight online/offline; il pannello seguiva il fight della scheda ma il consumo leggeva quello selezionato in precedenza. La controprova senza allineamento riproduce4 errori. Intercettazione vincolata al fuggitivo, gratuità corretta anche in caso di fuoco amico, Sfinimento e richieste scadute rispettati.
- Dado: intercettazioni1d16 reali, non soltanto etichetta. Critico del dado, doppio critico, Fortuna magica, anteprima e metadati coerenti; vecchie richieste prive di metadati restano leggibili come d20. Naturali non validi respinti prima del consumo remoto. I19 casi del nuovo file fuga sono passati nel gruppo conclusivo.
- Updater isolato:9/9 Windows,4/4 sostituzione cartelle,7/7 firma e12/12 pubblicazione; report `build/oct28-updater-independent-validation.json`. Controllo ultima scrittura/rilettura:11/11, senza chiusura dell’app o avvio installer dopo errore. La compatibilità del vecchio helper è un test isolato del formato, non una prova grafica di tutte le vecchie versioni.
- Gruppo intermedio completo:83/83 passati. Gruppo successivo:92 passati,1 fallito per la fixture Reazioni della nuova Mazza; corretta l’inizializzazione del pool senza indebolire le verifiche. Mazza rieseguita6/6, poi **18/18** nel gruppo finale Mazza/Guardiano/log (`build/oct28-post-session-final-confirmation.log`). Non sommare questi gruppi come test distinti.
- Mazza d’oro usa il percorso reale di attivazione configurata: conferma costo, Oculum2/4/6, A/R/RV, CD4/6/8, durata casuale persistente, scadenza e sostituzione senza accumulo. Le Reazioni non avanzano il turno. I6 test comprendono pagamento e blocco della seconda attivazione immediata.
- Guardiano: v4 esplicitamente approvata dopo rifiuto della corda delle pose precedenti; desktop, ricomposizione telefono e reliquia finale superano8 prove su320/834/1440px, controllo dei clic, margini, pagina comprata e alpha reale. I test automatici non provano da soli la geometria dell’arco; l’approvazione visiva è distinta.
- Analisi statica finale: **nessun problema trovato**,159,8s, `build/oct28-post-session-release-analyze.log`. Il catalogo è1193 voci,21 scene dedicate collegate e1172 ancora da completare; la patch non chiude l’intero arretrato degli artwork.
- La nuova build GitHub, i pacchetti locali e i download pubblici richiedono la verifica del nuovo commit dopo questi controlli; le prove della precedente bb7e restano riferite esclusivamente a quel commit.
