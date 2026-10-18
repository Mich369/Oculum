# Patch combattimento, parser e cataloghi — 18 ottobre 2026

## Regole confermate e riferimenti

Leggere [il registro delle conferme](OCULUM_REGOLE_CONFERMATE.md) e [il manuale integrale](manuale-consultazione.md). Il manuale è visibile anche nella pagina Regole dell'app. `AGENTS.md` impone di consultarli prima di modificare il regolamento e di chiedere chiarimenti sui punti mancanti.

## Attacchi e difese online

Nella scheda e nella turnistica compare **Attacca un bersaglio** quando la scheda è partecipante a un combattimento online. Il dialogo sceglie il bersaglio e VC o un sottotratto sbloccato. I tiri alternativi richiedono una motivazione scritta. Il tiro usa il dado già presente nella schermata attuale.

Il bersaglio vede una richiesta nel suo log e il pannello **Difese e reazioni in attesa**, con CM, Riflessi, Resistenza e Manifestazione del Potere. I sottotratti non disponibili sono disabilitati. Il confronto segue la difficoltà: fasce 1–6/1–5/1–3; Oculum pari o uno sotto. Nel quasi riuscito la Difesa numerica vale ×1,5 per eccesso, e le durate sono dimezzate per difetto fino a zero.

Un attacco doppio dà un critico; una difesa doppia dà una reazione critica gratuita contro l'attaccante. Solo il bonus critico per difficoltà/livello viene raddoppiato. Difesa, Scudi, Fragilità, resistenze e Pawn passano dal percorso danni esistente. Le richieste hanno ID, ambito campagna e incontro, controllo della presenza del mittente e stato salvato: una replica non riapre una risoluzione già completata.

Le probabilità distinguono evitato, ridotto e pieno. Se la difesa non è condivisa la probabilità resta sconosciuta: non si leggono di nascosto le statistiche dei nemici da copie locali.

## Offline: funzionamento manuale

Restano disponibili i tiri e il pannello Danno/Cura. **Quasi riuscito · Difesa ×1,5** applica la protezione maggiorata al danno inserito. Nel dialogo Critico si possono impostare difficoltà, livello e l'opzione del critico da tiro doppio.

Un effetto destinato al bersaglio viene preparato senza applicare il debuff al lanciatore. Nell'elenco effetti, il bersaglio locale si sceglie dal pulsante a mirino dopo il confronto manuale della difesa. L'effetto viene scritto nella scheda selezionata e si ritorna alla scheda d'origine. Le durate possono essere modificate nell'editor, anche per rispettare un esito ridotto risolto manualmente.

## Sei tecniche necromantiche distinte

Restano invariati mostri, ID, statistiche, drop e Richiamo dei servitori. Le sei vecchie descrizioni generiche sono sostituite da definizioni che generano sia il testo del Book sia gli effetti importati. O indica l'Oculum effettivamente investito.

| Tecnica | Forma I / II / III | Costi I / II / III | CD personali |
|---|---|---|---|
| Legacci del focolare spento | Immobilizzato 1 / 2 / 3 turni su un bersaglio dopo la difesa | 3/3 · 6/6 · 10/10 | 3 · 4 · 5 |
| Lucignolo dell'anima | Bonus al prossimo attacco O+6 / O+12 / O+20 | 1/4 · 5/10 · 11/20 | 1 · 1 · 2 |
| Catena del sepolcro nero | Immobilizzato 1 / 2 / 3 turni sul bersaglio e Scudo proprio 2O / 3O / 4O | 1/4 · 5/10 · 11/20 | 2 · 3 · 4 |
| Eclisse nelle orbite | −2 / −3 / −5 VC al bersaglio per 1 / 2 / 3 turni; Scudo proprio 2O | 1/4 · 5/10 · 11/20 | 1 · 1 · 2 |
| Marchio della bocca vuota | Rallentato 1 / 2 / 3 turni e bonus al prossimo attacco O+4 / O+9 / O+16 | 1/4 · 5/10 · 11/20 | 1 · 1 · 2 |
| Banchetto dell'ultimo respiro | Cura propria 2O / 3O+4 / 4O+8; −2 / −3 / −4 Difesa per un turno | 1/4 · 5/10 · 11/20 | 3 · 4 · 5 |

I requisiti sono livello 0 / 3 / 6. Il controllo si può evitare col tiro difensivo. Nel quasi riuscito 1 turno diventa 0, 2 o 3 diventano 1. I costi sono variabili solo dove O cambia un effetto reale; i Legacci hanno costo fisso.

## Parser e consultazione

- Il nuovo parser riconosce formule numeriche, Oculum investito, alcuni stati di controllo, bonus ai tiri, cura, Scudo, reazioni e durata. Separa costo e requisito di livello dagli effetti.
- Nell'editor c'è **Parser abilità · formule e requisiti**. Il testo originale resta intatto, il testo non riconosciuto viene segnalato, e un secondo riconoscimento non aggiunge le stesse righe.
- Gli ID degli effetti riconosciuti sono stabili e distinguono testi diversi.
- Nel Monster Book si può aprire l'anteprima delle meccaniche dalla creatura; nel catalogo compaiono le formule effettivamente importate. I pannelli mostrano le tre forme e le cinque evoluzioni quando previsto per una Defiled Art.
- Le varianti dello Slime Roccioso importano il suo kit specifico e i costi originali, senza confonderli con una tecnica generica.
- I Libri Runici spiegano che le parole permettono di comporre una Rune Art e inventare skill con il Master, definendo effetti, bersagli, costi, DT, durata e CD. La spiegazione compare anche nei pannelli delle Rune Art già esistenti.

## Cosa puoi modificare

### Aggiornamenti del 18 ottobre

- Pergamene: l'uso consuma un esemplare ed esegue la tecnica; l'apprendimento è un controllo separato, solo con 20 naturale e totale ≥30+10×grado. Probabilità Facile/Medio/Difficile/Oculum: 20/15/10/5%. Conferma e log mostrano la probabilità della campagna; il log registra anche il consumo.
- La barra sotto i comandi di combattimento raggruppa Skill equipaggiate, Art in uso e Open in Attacco, Difesa e Aiuta compagno. La scelta della forma passa dai gestori originali di costo, livello e cooldown. Le passive non compaiono come attivazioni manuali.
- Colori delle abilità: Oculum personalizzato, Resilienza verde, Volontà rosso, Materia blu. Le abilità senza risorsa riconosciuta usano il testo del tema.
- Manifestazione del Potere: controllo esatto del 13% per consumare 1 Oculum, una volta per tiro. La difesa online richiede una descrizione.
- Resistenza riuscita online: 1 danno assorbibile dagli Scudi e contrattacco gratuito ordinario; solo il tiro difensivo doppio lo rende critico. I contrattacchi non possono generarne altri.
- Gli stati con durata in azioni mantengono questa unità, senza essere convertiti in turni.

### Richieste successive ancora da completare

Non sono comprese in questa patch: modalità universali separate Attacco/Difesa/Fuga/Supporto con editor completo; i tre nuovi mostri Costrutto Rinsecchito, Larva Bianca e Falena del Torpore con relativi gestori specifici, nidiata e bottino; Open uniche per tutti i mostri; annullamento transazionale di tutte le conseguenze tramite Ispirazione; intero aggiornamento di Aiuta compagno e dei requisiti dei sottotratti alternativi. La fuga della Larva è già registrata su Velo, ma la nuova creatura non è ancora implementata. Queste richieste restano aperte: non sono implicitamente completate dal parser o dalla barra rapida.

Resta inoltre da collegare il nuovo gestore IA: intervento dopo un turno passato senza azioni manuali e uso di una Reazione ancora disponibile prima del ripristino. Nessun debito al turno seguente: una Reazione di base, eventuali aggiunte solo tramite Skill, ripristino a ogni nuovo turno proprio senza accumulo.

Negli editor della scheda: nome e descrizione, forme, tipo attivo/passivo, risorsa di costo, minimo/massimo, cooldown, formula, dado, bersaglio/destinatario, elemento, condizione, durata/unità, accumulabilità e opzioni di Difesa/Scudi. Le modifiche restano nel JSON; aggiornare il catalogo non sovrascrive automaticamente le schede già personalizzate.

Per il catalogo sorgente, le tecniche necromantiche hanno una sola definizione in `lib/pages/oculum_dungeon/concrete_monster_techniques.dart`. Le regole di confronto sono separate dalla UI in `lib/game/oculum_opposed_attack.dart` e coperte da test sui confini delle fasce.

## Limiti da non confondere con verifiche concluse

Il parser non interpreta automaticamente ogni frase narrativa o condizionale del catalogo. Un effetto non riconosciuto va definito nell'editor con il Master; non gli si attribuisce un bonus generico per nascondere il problema. Le capacità con gestore dedicato, come Pawn e Riccio Aculeo, continuano a usare quel gestore.

I test di consegna simulano il protocollo e verificano identità del mittente, duplicati ed esiti salvati. Non sostituiscono una prova tra due dispositivi reali su Supabase. Build, pubblicazione Pages e installazione della distribuzione vanno riportate separatamente al termine delle rispettive verifiche.
