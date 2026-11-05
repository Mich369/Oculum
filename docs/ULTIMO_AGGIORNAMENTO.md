# Ultimo aggiornamento — 5 novembre 2026

**Patch del 5 novembre, verifiche locali:**

- Nuove schede con 3 punti Fortuna magica; anteprima e spesa facoltativa per scheda nei tiri supportati. Corretti il controattacco con token in ritardo e la spesa su richieste difensive scadute.
- Mostri ordinari con tre Skill e una Open da pool coerenti. Le firme personali restano attualmente fissate: estensione del sorteggio ancora da scegliere.
- Sette nuove creature del Ghiaccio e anatomia degli Idrax senza arti. Dodici desktop approvati collegati ai temi.
- Ritirati Ragno degli Obser Falsi, Errante con la Sedia e con l’Ombrello, comprese le varianti; schede e fonti degli Occhi già salvate conservate.
- Pronte 2.410 alternative A/B per 1.205 creature attive; rimangono proposte da votare.

Analisi statica completa di sorgenti e test senza problemi. Nove prove dedicate ai fix Fortuna e 16 regressioni collegate passate; 54 verifiche del gruppo ritiro/manuale passate. La suite completa aveva dato 2.260 passati, sei saltati e sei fallimenti di aspettative/fixture, poi risolti in prove mirate: non è dichiarata una nuova suite completa verde. [Evidenze e perimetro](PATCH_2026-11-05_FORTUNA_POOL_GHIACCIO.md).

Base delle verifiche: `2765a5df`. CI, pacchetti firmati, pubblicazione e installazione hanno riscontri separati nel rapporto di consegna; i soli test locali non li certificano. [Consegna precedente](CONSEGNA_VERIFICATA_2765a5df.md).

Modificabili: saldo e opzione Fortuna per scheda, statistiche, Skill/Art/Open, requisiti, costi, effetti, bersagli, durate, recuperi, equipaggiamento, immagini, temi, reliquie e anatomie. [Registro cumulativo](REGISTRO_AGGIORNAMENTI.md).
