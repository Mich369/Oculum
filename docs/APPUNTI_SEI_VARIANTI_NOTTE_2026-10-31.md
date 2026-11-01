# Proposte notturne: sei alternative e controlli anatomici

## Revisione verificata del 1 novembre

I quattro problemi descritti nello storico sotto sono stati riprodotti e corretti localmente: ali da «scanalata», occhio singolo delle monete, radici dell’habitat aggiunte a Rascalume/Mìrula e classificazione Robot degli Empatici. La regressione iniziale ha fallito in quattro casi; il gruppo finale, inclusa l’anatomia bipede confermata di FireShield, ha superato 62 test. Restano prioritarie le anatomie personalizzate e gli altri robot di Postea. Log: `build/anatomy-fire-biped-final.log`. CI e pacchetti successivi sono verifiche separate. I riferimenti sprite incompatibili delle quattro specie saltate rimangono aperti; nessuna sostituzione arbitraria.

Meccanio F2, Malconcio A2 e Primitivo C2 canonici, insieme ai sei derivati approvati separatamente. FireShield richiede sei proposte nuove: due braccia, due zampe, altezza5m; le vecchie alternative a sei arti sono solo storico.

Richiesta diretta: «io ora vado a dormire prepara intanto 6 versioni per ogni mostro andando più avanti possibile».

La nuova consegna richiede sei scelte A–F per ciascuna creatura trattata. Le lettere sono alternative visive della stessa specie, non sei nuovi mostri. Originali e revisioni restano conservati; eventuali proposte precedenti possono essere riutilizzate dichiarandolo. Nessuna approvazione viene dedotta dall'assenza dell'utente. Le domande si accumulano per il risveglio, senza bloccare i lotti con anatomia già definita.

La galleria e il conteggio effettivo vengono rigenerati da `output/artwork/sei_varianti_notte_2026-10-31/INDICE_SCELTE.json`. Sono distinti dalla build 0b82cb37: non sono nuove immagini installate nell'app. Cuore Filo e le sue varianti rimangono esclusi, come richiesto.

## Verifiche da affrontare nella revisione successiva

Questi due problemi preesistenti sono emersi confrontando descrizioni e inventario anatomico durante la produzione. Non sono correzioni incluse nella build congelata 0b82cb37 e non hanno ricevuto nuovi test Flutter in questa consegna.

- **Meccanio:** `planar_monsters.dart` descrive una «sola ruota nera scanalata». Il rilevatore delle ali in `monster_anatomy.dart` cerca `alata` senza delimitazione di parola e può interpretare la sottostringa di «scanalata» come ali. L'audit del lotto registra la discrepanza. Le proposte mantengono una ruota, due braccia e nessuna ala. Correzione prevista: riconoscimento di parole intere e regressione sulle descrizioni con «scanalata».
- **Obser Sunshine:** la descrizione in `canonical_monster_variants.dart` indica «un occhio che brilla d'oro». Il conteggio generico riconosce «uno» e «una», ma non l'articolo «un»; in assenza di altra specificazione può ricadere su due occhi. Le proposte conservano un unico occhio inciso, come la descrizione. Correzione prevista: conteggio esatto dell'occhio e regressione per entrambe le monete Observer’s Tear e Obser Sunshine.

La correzione dei bersagli colpibili deve precedere qualsiasi dichiarazione di anatomia allineata al 100%. I disegni non introducono immunità, Skill, drop o nuove regole.

## Ambiguità raccolte dagli altri lotti

- **Rascalume e Mìrula:** il testo fisico completo permette le proposte, pur senza sprite dedicato. L'inventario anatomico aggiunge «Nodo delle radici», non descritto come organo corporeo; l'accesso a quel bersaglio va verificato separatamente, senza disegnare radici nuove per giustificarlo.
- **Riferimenti sprite incoerenti, specie saltate:** `fetal_man`, `headless_man`, `slime_blu` e `slime_blu_helmeted` hanno file collegati che mostrano goblin incompatibili con le descrizioni. I percorsi esatti e le domande sono in `lotto_radici_acqua/DOMANDE.md`. Non è una prova di quale immagine venga effettivamente mostrata in ogni schermata runtime: non vengono sostituite fonti o anatomie senza chiarimento.
- **Empatici:** lo snapshot anatomico esportato assegna Costrutto/Robot ai due ID Empatici, mentre le descrizioni effettive e le specie comuni di riferimento li descrivono organici. Segnalazione e snapshot in `lotto_empatici/ANATOMIA_AUDIT.json`; causa non ancora verificata, nessuna immunità o regola meccanica aggiunta. Le vecchie descrizioni di orecchie da coniglio/criniera d'oro sono invece già sostituite dall'override canonico applicato da `canonical_monster_variants.dart`: non richiedono una nuova scelta.

## Domande raccolte

Ogni lotto contiene `DOMANDE.md`; l'indice genera `DOMANDE_RACCOLTE.md`. Le domande chiedono la scelta della lettera e soltanto i dettagli non già definiti. Sorgenti, personalizzazioni, salvataggi e distribuzione non vengono modificati dagli artisti.
