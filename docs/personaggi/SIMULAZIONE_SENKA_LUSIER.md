# Scenario Senka livello 12 contro Lusier III

## Aggiornamento del29ottobre — misure del report attuale

Il [report prodotto dal test](../../output/simulation/Senka_Lv12_vs_Lusier_III.json) registra **301 PT per entrambe le schede prima delle Open**; la copia mascherata di Senka parte da558/558 Vita. È applicazione delle nuove [regole Vita/PT](../CONFERME_2026-10-29_PREMI_GUARDIANI.md#vita-per-livello-bonus-pt-e-visibilità--ultima-conferma); il [ciclo Open](../CONFERME_2026-10-29_PREMI_GUARDIANI.md#nuova-regola-generale-open) sostituisce le durate precedenti. La misura298 della prova del28ottobre resta storica. Questo scenario controllato è distinto dal duello fra i due codici personali del29ottobre e non cambia il suo esito documentato.

Scenario riproducibile nel test `test/oculum_senka_lusier_duel_test.dart`. Il codice originale di Senka rimane livello 1 e il test verifica che il file non venga modificato.

La copia di Senka viene portata a livello 12, Grado 0, con evoluzioni compatibili predisposte e maschera attiva. I punti base aggiuntivi sono assegnati soltanto alla copia di prova fino a ottenere la stessa Potenza Totale misurata di Lusier:301 prima delle Open nel report attuale. L'allocazione è registrata nel report, non costituisce una modifica alla crescita delle regole.

Il test passa attraverso il risolutore di difesa usato dai combattimenti locali e condivisi, applicando davvero Danni, Difesa, Scudi, intangibilità e ricevute. Verifica cinque carte di Lusier con risultati controllati 7/11/17/19/23, consumo del mazzo senza duplicazioni, un cambio di turno del tracker, costo del mantello, attraversamento di un colpo fisico, evocazione/assorbimento di un clone e Mille Tagli con Sfinimento alla fonte. La preparazione della raffica lunare usa seme 17; la sua distribuzione non è inclusa nello scenario.

Soltanto dopo il superamento, il test scrive `output/simulation/Senka_Lv12_vs_Lusier_III.json` con PT, allocazione, Vita, Scudi, totali, risorse e ricevute effettivamente osservate. La presenza del sorgente di test non ne attesta il superamento.

È una sequenza limitata del motore con totali controllati, non una partita completa né una misura del bilanciamento o delle probabilità di vittoria. Non dichiara un vincitore. L'interfaccia dei dadi, tre client indipendenti, prese e teletrasporto restano verifiche separate.
