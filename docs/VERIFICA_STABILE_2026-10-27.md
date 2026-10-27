# Verifiche locali della versione stabile del27 ottobre

- `dart analyze lib`: No issues found. Nessun errore, avviso o segnalazione informativa rimasta.
- `build/oct27-stable-final-tests.log`:55 test passati in13 file, compresi assegnazioni, trasferimenti, patch, risorse, elementi, personaggi e audit Titoli Item.
- Audit nuovo:51.327 equipaggiamenti da1.189 creature;17.109 per famiglia arma/armatura/scudo. Conversione costo3, conservazione delle capacità originali, bonus e materiali, crescita positiva, blocco quest, JSON e upgrade idempotente.
- Dopo la correzione dei costi come malus passivi:20 test mirati ripassati in `build/oct27-final-cost-scout-transfer.log`, comprendenti Senka, Lusier, osservazione e invio schede.
- Senka attuale senza maschera: RES9/VOL9/MAT8/OCU9,90/90 Vita. Maschera gratuita, riserve e Scudo riparabile, cloni con Vita separata e limite totale, fusione verificati localmente.
- Lusier III: livello13/GradoI, PT effettiva277 con equipaggiamenti attivi, Vita massima600,1 Scudo critico,150 Scudo Oculum. Budget core222 prima dei bonus degli oggetti. La PT è il totale delle quattro statistiche effettive più livello e3×Grado, non include direttamente il Danno della spada.
- Le schede esportate sono JSON/OC3 privi di account e tag online privati; il testo non aggiorna il runtime di una vecchia app.

## Limiti e lavoro ancora da completare

I test di trasporto e salvataggio non sono una prova di due app realmente collegate. Teletrasporto, Mille Tagli, Open lunare e automatismo completo delle loro quest rimangono evoluzioni in lavorazione; maschera mirata/solidità durante il proprio attacco e fusione in sessioni UI condivise richiedono ancora verifiche specifiche. Forma Slime, Assorbi e grandi espansioni di catalogo non sono dichiarati completati da questo resoconto.

La telepatia con soglia6 Oculum e il−3 dopo dichiarazione ad alta voce sono riservati esplicitamente AL PROSSIMO COMMIT, nel checkpoint locale escluso dalla build.

Build GitHub, pacchetti locali, download anonimi e sessioni reali vanno attestati separatamente, con commit e run effettivi. Questo documento attesta le verifiche locali sopra elencate.

## Recupero delle regressioni della CI 40556507431

La CI del commit a3529403 ha passato l'analisi ma fallito 45 test (1.248 passati, 6 saltati). Il controllo locale dei file coinvolti ha successivamente passato 188 test; i casi ancora falliti sono stati affrontati separatamente. Il gruppo successivo ha passato 54 test, compresi Senka e Lusier, restando sul caso degli ID delle Skill nei drop. I conteggi si sovrappongono e non vanno sommati. La fixture del Master ora seleziona Party/permessi Master espliciti; i test storici verificano le tecniche originarie separatamente dalle dodici tecniche aggiuntive. Le quattro micro realtà annunciate restano in lavorazione e non sono certificate dai test dei sei reami precedenti.

Correzioni reali: tecniche Larva duplicate, costi non Oculum bloccati dalla riserva Oculum, configurazioni dei costi cambiate al caricamento, Maestria testuale, risorsa Follia, indicizzazione delle scroll di crescita e mantenimento degli ID delle Skill salvate. L'esito della nuova CI e la distribuzione devono essere verificati sul nuovo commit prima di dichiarare la pubblicazione riuscita.

Controllo finale locale: build/oct27-drop-characters-final.log, 7 test passati; include il drop con ID preservati e le due schede corrette. Ultimo gruppo precedente: gli altri 54 test sono passati. L'analisi lib+test aveva segnalato una sola parentesi graffa nel test, corretta prima del commit.


Correzione bersagli: build/oct27-fight-targets-final.log,16 test passati; comprende selettore online/offline nel fight della scheda, nessun bersaglio senza spesa, turnistica/reazioni, consegna attacchi, contrattacchi e appartenenza ai fight condivisi. build/oct27-fight-targets-analyze.log: No issues found. Queste sono prove locali e trasporto simulato, non due app collegate realmente.
Firma: corretto il pin verso il certificato effettivo della chiave stabile GitHub (f883a37...), verificato dal job122454651673. L'APK locale precedente ha ae37f080... e resta legacy; non è stato modificato né dichiarato aggiornabile con la chiave GitHub. Nuova distribuzione ancora da verificare sulla CI seguente.
