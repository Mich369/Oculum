# Scostubandito Errato e Veterano dell'Errato — verifica della patch

Stato: implementazione locale in attesa di compilazione e test coordinati. Nessuna attestazione di pubblicazione o di prova fra dispositivi reali.

Riga da sottoporre all'utente prima della chiusura al 100%: **Errato e Veterano dell'Errato: soltanto a fine fight vinto derubano gli avversari sconfitti e rimasti; Errato 75% degli Obser personali e del numero degli oggetti rubabili, lasciando in vita; Veterano 100% e uccisione. Titoli Item esclusi. Vincitori e fuggiti con successo salvi. Un Veterano valido concede +5% Volontà agli Errati alleati e +15% a sé, senza accumulo fra Veterani. Un suo colpo riuscito dà solo agli Errati +2 per colpire quel bersaglio fino al prossimo turno del Veterano o a una difesa riuscita del bersaglio, rinnovando senza sommare.**

Adattamento nel motore:

- Le nuove varianti lasciano temporaneamente la vittima a una Vita e KO: la rapina e l'eventuale uccisione sono rinviate alla chiusura dello scontro. Il comportamento immediato dei vecchi Scostubanditi ed Empatici resta distinto.
- Una vittima di queste nuove varianti curata sopra una Vita può rientrare nel combattimento: il vecchio flag di KO non deve trattenerla artificialmente fino alla rapina.
- La chiusura genera una risoluzione trasportata insieme ai premi del fight; un avversario ancora capace di combattere impedisce di dichiarare la vittoria dei banditi. I fuggiti non vengono trattenuti né derubati.
- La percentuale degli oggetti riguarda le quantità, non il prezzo: quattro oggetti singoli ne perdono tre; una pila di quattro unità ne perde tre. Arrotondamento per difetto, come per gli Obser. La selezione segue l'ordine dell'inventario per rendere riproducibile il risultato.
- I Titoli Item, la maschera personale di Senka e gli oggetti esplicitamente non rubabili sono esclusi. Se un equipaggiamento viene sottratto del tutto, vengono rimosse anche la sua quota residua di Scudo e le condizioni che produceva.
- La ricevuta è conservata nel JSON della scheda in `planarRuntime.claimedScostuSettlementIds`, anche dopo riposo o nuovo fight. Un reinvio non sottrae nuovamente denaro o oggetti.
- L'aura è calcolata dalla presenza attuale di un Veterano vivo, presente e non KO. Il bonus percentuale è arrotondato per difetto e non viene scritto nelle statistiche base.
- Il bersaglio favorito è una marcatura temporanea del Veterano; il totale resta +2 anche dopo altri colpi. Un cambio del turno personale, una difesa riuscita o la scomparsa del Veterano lo rende inutilizzabile.

Personalizzazione preservata: inventario e quantità, tag di oggetto non rubabile, statistiche base e crescita, Skill, costi e definizioni personali dei mostri rimangono nei loro editor e JSON. I numeri canonici 75/100 e 5/15/+2 restano quelli confermati dall'autore.

Sei test predisposti in `test/oculum_errato_veteran_runtime_test.dart`: vittoria/fuga/sconfitta ancora contestabile; Veterano morto o fuggito e aura non cumulativa; 75% di quattro oggetti con esclusione Titoli, salvataggio e replay; 100% e morte soltanto a fine fight; vittima curata nuovamente attiva; marcatura +2 con rinnovo, difesa e cambio turno. Esiti da riportare soltanto dopo l'esecuzione.
