# Aggiornamento Oculum — 23 ottobre 2026

## Modifiche

- 228 nuove specie; filtri per piano/microrealtà; aggiornate quattro creature esistenti senza duplicarle. Elenco: NUOVI_MOSTRI_PER_PIANO.md.
- Tre quest condivise, ricompense e ricevute persistenti nella cassa comune.
- Effetti planari, Fluttuare confermato, cariche, contatori difensivi, Bringi e malanno Annichilimento.
- Vita e Oculum sopra le barre, numeri allineati a destra e adattati alla larghezza.
- Tutorial: razza Figli di Madre Natura e otto Art elementali aggiuntive.
- Pulsante aggiornamenti, controllo all’avvio e al ritorno nell’app, controllo periodico limitato; backup JSON verificato, pacchetti SHA256, protezione dalle regressioni e riavvio desktop.
- Firma Android stabile tramite secret privato; conferma installazione gestita da Android. Nessuna disinstallazione automatica.
- Download pubblici di tutti gli archivi riusciti, inclusi Web/iOS non firmato/catture nel menu web; controllo senza credenziali prima di promuovere il canale.

## Personalizzabile

Monster Book: nome, aspetto, habitat, livello, quattro statistiche, ruolo, punto debole, resistenze, equipaggiamento, drop e regole speciali JSON.
Editor abilità: descrizioni delle tre forme, requisiti, costo, ricarica, bersagli, quantità, durata, dadi, condizioni e relativi effetti. Gli effetti già personalizzati nel salvataggio conservano precedenza.
Oggetti e scroll: peso, quantità, prezzo, livello, Grado, abilità ed effetti; apprendimento tramite l’editor esistente.
Le percentuali delle quest sono quelle confermate, non una nuova impostazione del giocatore. Il Master può modificare inventario e Obser della cassa con i controlli esistenti.

## Verifiche distinte

Consultare il resoconto finale per esiti aggiornati di test locali, build, GitHub CI, download pubblici, sito e prove online reali. La presenza del codice non dimostra da sola il superamento di tutte queste verifiche.

## Completamenti ancora necessari

Alcuni effetti narrativi richiedono ancora una scelta del Master: attrazione dei nemici verso la forma-nuvola, scelta automatica del migliore fra tre elementi del Golem e propagazione del critico della sua barriera. Il nuovo aggiornamento macOS/Linux richiede Python 3 e va provato sui sistemi reali. Il rientro entro il piano gratuito Supabase richiede ancora misurazioni e riduzione dei dati/TOAST: non è certificato da questo aggiornamento.

## Ulteriori conferme

Solo le sei nuove tecniche preparate, due delle quali a carica crescente usano le due fasi; scroll disponibili con apprendimento normale. Il bonus +3 × Grado appartiene alla sola scroll. Controllo di mantenimento solo con perdita Vita, penalità −10 punti per due Gradi di divario, −20 per tre. Potenziamento nella riga Tiri e azioni: selezione numerica verificata e consumo al prossimo tiro; bonus anche al mantenimento.
I costi strutturati mancanti nel testo vengono mostrati senza sovrascrivere i testi personalizzati. L’elenco effetti usa una colonna a dimensione naturale con comandi Sposta su/giù. Nuove varianti coerenti: Raggio di luce, Lame dell’aurora, Raggio necromantico, Mano del sepolcro, Presa di ghiaccio, Raggio di brina. Bonus delle tecniche pagate con Volontà/Materia inizialmente +20%, modificabili.

Le due tecniche a carica crescente (Raggio dello Zenit e Nucleo della folgore) costano 2 Oculum all’attivazione; incrementi 40/80/120/180%, 1 Oculum e una Azione per incremento personale, massimo tre. Progressione e costo di mantenimento modificabili nell’editor.

## Ultime aggiunte
Identità Fato/Chaos con premi per nuovo Grado non ripetibili (6/14/30/40/9/1%), occhi con gesto solo al clic Master, ritratto più largo del 20%, galleria reliquie in quattro colonne con ricerca e predefinita del tema, Copia/Scarica sul ritratto ingrandito.
Cristalli Dust conservabili, distruttibili a scelta o utilizzabili per fusione; prezzi 40–60/90–120/150–200 e rese 1d3/1d6+2/1d10+2. Fusione +1/+2/+3 statistiche, +10/+20/+30% Art per 1d3/1d6+1/1d10+2 Riposi Lunghi. Board conservata per party e alleati alla fine del fight.
Parassita larvale e Martire Mortale; relativi valori e regole nel registro. Le verifiche online reali del controllo parassita restano da completare prima di certificarlo.
