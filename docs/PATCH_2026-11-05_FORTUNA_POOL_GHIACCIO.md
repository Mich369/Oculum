# Patch del 5 novembre — sorgenti in preparazione

## Fortuna e conferma dei tiri

Le nuove schede iniziano con tre punti nella Fortuna magica esistente. Un caricamento conserva il saldo salvato, compreso zero; non assegna di nuovo i punti. L'opzione per scheda «Proponi Fortuna dopo il tiro», nelle Risorse e nei Dadi rapidi, mostra naturale e totale prima della conferma dei tiri interattivi supportati. Ogni punto speso aggiunge uno al totale, senza cambiare il naturale. I percorsi specialistici e le risoluzioni automatiche non diventano tutti interattivi per deduzione.

La revisione indipendente ha individuato due errori nei controlli del nuovo dialogo:

- Il controattacco gratuito poteva perdere il suo bersaglio autenticato quando il relativo token non era ancora arrivato nello snapshot. Il controllo finale ora conserva soltanto la stessa autorizzazione, nello stesso scontro e ambito, con la reazione reclamata da quell'azione. Un token già noto ma fuggito non viene reinserito.
- Una richiesta difensiva rimossa o sostituita durante il dialogo poteva consumare Fortuna prima del rifiuto della difesa. Prima della spesa vengono ora controllati identità della richiesta, stato pendente, ambito, scontro, bersaglio e controllo della scheda.

Tutte le nove prove UI/integrazione dedicate sono passate: conferma con zero/un punto, richiesta rimossa o sostituita, reazione revocata, bersaglio fuggito e difesa valida o scaduta. Il trasporto è simulato: non è una nuova prova online autenticata. Log: `build/patch-20261105-fortune-commit-focused-01.log`. Le sedici regressioni collegate sono passate nel precedente gruppo coordinato; i nove nuovi casi allora avevano fallito soltanto nell'attesa delle animazioni, corretta nel test senza cambiare le animazioni dell'app.

## Kit dei mostri e Ghiaccio

Le specie ordinarie dispongono del pool di almeno nove Skill e due Open. La creazione estrae tre tecniche distinte privilegiando quelle utilizzabili al livello corrente e una tecnica a più bersagli, se disponibile. I salvataggi esistenti e i kit personalizzati non vengono risorteggiati. Sono conservate le eccezioni autoriali, comprese specie senza Art e creature con una sola abilità.

**Scelta ancora aperta:** la seconda Open viene sorteggiata per le Open generiche; quelle personali restano attualmente fissate. È stata chiesta una scelta separata sull'estensione del sorteggio alle Open personali delle specie ordinarie. Questo limite non viene descritto come già risolto.

Sette nuove voci: Costrutto dei Tre Crani, Scheletro delle Lame di Brina, Cacciatore della Cresta Glaciale, Arciere del Gelo Cavo, Gigante della Clava Polarnotte, Ice Shield e Idrax Glaciale. Ice Shield usa Scudo normale. Idrax base, Errante e Glaciale conservano l'anatomia da serpente, senza arti aggiunti dal pool.

## Manuale, compatibilità e immagini

Ritirate dalle nuove selezioni le specie richieste: Ragno degli Obser Falsi, Errante con la Sedia ed Errante con l'Ombrello, comprese le rispettive varianti. Le definizioni storiche restano disponibili per schede e Occhi già salvati; i nuovi incontri e il Mercato Nero non le ripropongono. Gli altri Erranti conservano la propria voce. Manuale interno bilingue e copia di consultazione sono allineati in 82 sezioni.

Dodici desktop già approvati sono collegati ai temi: due Minotauri, due Mimic, Troll Veterano, i sei primi mostri del Ghiaccio e Idrax base. Le alternative A/B delle 1.205 creature attive sono proposte da votare, conservate separatamente; non vengono installate al posto delle immagini canoniche. Le revisioni d'inquadratura mantengono le versioni precedenti.

## Verifiche e consegna

La regressione completa locale è terminata con 2.260 test passati, sei saltati e sei fallimenti. Quattro erano aspettative precedenti sulle eccezioni dei kit; due erano fixture del danno che conservavano Fortuna casuale. Tutti quei casi sono poi passati nelle riesecuzioni mirate. Non viene dichiarata una successiva suite completa verde. I log dei tentativi, compresi quelli falliti, restano in `build/patch-20261105-*.log`.

Analisi statica finale, CI, firma APK, download pubblici e installazione dei pacchetti hanno verifiche separate. Alla stesura di questo rapporto la distribuzione attiva resta quella verificata di `2765a5df`; la chiave Android stabile non è configurata localmente e non viene sostituita. Nessuna riga viene chiusa al 100% senza la conferma richiesta nel registro.

## Cosa resta modificabile

Saldo Fortuna e opzione di anteprima per ogni scheda; statistiche, Skill e Open assegnate; requisiti, costi, bersagli, elementi, effetti, durate e recuperi; equipaggiamento, immagini, temi, reliquie e anatomie personalizzate. Gli editor e il JSON della scheda conservano queste scelte. La selezione di una proposta artistica non assegna nuove capacità o nuovi drop.
