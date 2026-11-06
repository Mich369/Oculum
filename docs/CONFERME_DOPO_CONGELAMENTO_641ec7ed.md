# Conferme successive al congelamento di 641ec7ed

## Perimetro e provenienza

Fonte congelata e inviata alla CI: commit `641ec7ed6eb8bcfc0a737f6878b54b9dc2a0b30b`, run Build distribution `42022970211`.

Questo documento registra conferme ricevute **dopo** il congelamento di quella fonte. Il documento stesso non appartiene al commit `641ec7ed` e non viene attribuito retroattivamente ai suoi binari o al suo manuale incorporato. Non modifica codice, asset, test o documenti gia' congelati e non certifica un nuovo esito di CI, installazione o pubblicazione.

## Open personale dei mostri ordinari — 5 novembre 2026

Ambito della domanda: includere nel sorteggio anche la Open personale gia' definita per un mostro ordinario, oppure mantenerla fissa.

**Risposta dell'utente: «Mantieni fissa la Open personale».**

La conferma precisa il comportamento da conservare:

- La nuova scheda di un mostro ordinario conserva la sua Open personale; il sorteggio non la sostituisce con una Open alternativa del pool.
- Il sorteggio fra Open continua per quelle generiche generate, riconosciute come «Difesa totale», «Istinto vigile» e «Assalto finale».
- I kit speciali e le loro eccezioni restano invariati. Restano anche le scelte e le personalizzazioni delle schede gia' salvate.
- La scelta delle tre Skill ordinarie dal relativo pool rimane distinta da questa decisione sulla Open.

Questa risposta conferma il comportamento **gia' presente nella fonte congelata**, senza richiedere una correzione del codice durante la CI. In [oculum_starter_creation.dart](../lib/src/main/oculum_starter_creation.dart), il ramo di `oculumMonsterBookLoadout` sostituisce la Open soltanto quando riconosce una delle tre denominazioni generiche; le Open personali restano quindi fisse.

Le verifiche locali gia' svolte sul pool comprendono, in [oculum_monster_spawn_loadout_test.dart](../test/oculum_monster_spawn_loadout_test.dart), il sorteggio di tre Skill distinte e delle due Open generiche e la conservazione dei kit fissi e delle definizioni personali. La conferma successiva chiarisce l'intenzione autoriale di quel comportamento. Per questo documento non sono stati eseguiti nuovi test, nuove build o modifiche alla fonte compilata; non si estende la prova a una nuova verifica individuale di ogni specie.

## Registro separato delle scelte artistiche

I voti e le decisioni sulle alternative dei mostri sono raccolti in [SCELTE_ALTERNATIVE_MOSTRI_2026-11-05.json](SCELTE_ALTERNATIVE_MOSTRI_2026-11-05.json).

Il registro artistico conserva per ciascuna voce la scelta dell'utente, i riferimenti alle immagini e lo stato di integrazione. Una scelta canonica o il mantenimento del disegno precedente non certificano da soli una nuova integrazione, una build o una distribuzione. Le proposte non selezionate rimangono nello storico secondo la decisione registrata.
