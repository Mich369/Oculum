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
