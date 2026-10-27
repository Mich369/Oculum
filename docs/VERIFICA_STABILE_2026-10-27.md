# Verifiche locali della versione stabile del27 ottobre

- `dart analyze lib`: No issues found. Nessun errore, avviso o segnalazione informativa rimasta.
- `build/oct27-stable-final-tests.log`:55 test passati in13 file, compresi assegnazioni, trasferimenti, patch, risorse, elementi, personaggi e audit Titoli Item.
- Audit nuovo:51.039 equipaggiamenti da1.183 creature;17.013 per famiglia arma/armatura/scudo. Conversione costo3, conservazione delle capacità originali, bonus e materiali, crescita positiva, blocco quest, JSON e upgrade idempotente.
- Dopo la correzione dei costi come malus passivi:20 test mirati ripassati in `build/oct27-final-cost-scout-transfer.log`, comprendenti Senka, Lusier, osservazione e invio schede.
- Senka attuale senza maschera: RES9/VOL9/MAT8/OCU9,90/90 Vita. Maschera gratuita, riserve e Scudo riparabile, cloni con Vita separata e limite totale, fusione verificati localmente.
- Lusier III: livello13/GradoI, PT effettiva277 con equipaggiamenti attivi, Vita massima600,1 Scudo critico,150 Scudo Oculum. Budget core222 prima dei bonus degli oggetti. La PT è il totale delle quattro statistiche effettive più livello e3×Grado, non include direttamente il Danno della spada.
- Le schede esportate sono JSON/OC3 privi di account e tag online privati; il testo non aggiorna il runtime di una vecchia app.

## Limiti e lavoro ancora da completare

I test di trasporto e salvataggio non sono una prova di due app realmente collegate. Teletrasporto, Mille Tagli, Open lunare e automatismo completo delle loro quest rimangono evoluzioni in lavorazione; maschera mirata/solidità durante il proprio attacco e fusione in sessioni UI condivise richiedono ancora verifiche specifiche. Forma Slime, Assorbi e grandi espansioni di catalogo non sono dichiarati completati da questo resoconto.

La telepatia con soglia6 Oculum e il−3 dopo dichiarazione ad alta voce sono riservati esplicitamente AL PROSSIMO COMMIT, nel checkpoint locale escluso dalla build.

Build GitHub, pacchetti locali, download anonimi e sessioni reali vanno attestati separatamente, con commit e run effettivi. Questo documento attesta le verifiche locali sopra elencate.
