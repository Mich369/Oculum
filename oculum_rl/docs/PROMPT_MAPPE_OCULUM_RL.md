# Prompt definitivo per mappe, combattimento e resa di Oculum RL

Lavora nel progetto autonomo `C:\Oculum App\Oculum RL`. Leggi le istruzioni del repository e `docs/OCULUM_MEGA_PROMPT.md`. Parti dai salvataggi, dai mostri, dalle regole e dalle tavole confermate. Aggiorna il gioco esistente e consegna una prova avviabile con seed, percorso, versione e risultati ripetibili.

## Mappe da giocare

- Costruisci ogni piano con sale concepite per una funzione, soglie fisiche, passaggi a vista, bivi e anelli che riuniscono due percorsi. Il ritmo di esplorazione e combattimento si ispira a Wizard of Legend. Disposizione, simboli, texture e mostri appartengono a Oculum.
- Usa seed e numero del piano per cambiare ingressi, connessioni, arene, pericoli e ricompense. Verifica raggiungibilità dell’uscita, percorso di ritorno e possibilità di completare insieme le tre quest.
- Nella minimappa mostra sale e collegamenti scoperti. La mappa estesa indica mercanti, ristori e uscite incontrati. Permetti di segnare un punto. In cooperativa condividi le scoperte e usa un colore per ogni giocatore. Conserva loot, cancelli, ripari rotti e interazioni già eseguite quando si torna o si ricarica.
- Campo Scostubanditi. Il sentiero del mercante, la palizzata e il fianco sono riconoscibili prima della scelta. Prova col seed 251 un percorso a passo lento con un clone e uno di combattimento con ripari. La sentinella ascolta, cerca e reagisce alla visuale. Il Gran Scostumato conserva la condizione d’incontro.
- Foresta Elementale. I sentieri convergono sulla radura del Forest Demon. Regno Sotterraneo. Il passaggio d’andata è distinto dalla scorciatoia che si apre dall’interno. Regno Affogato. Rive emerse e pozze cambiano percorso e combattimento. Le scariche possono propagarsi nella stessa acqua con un segnale leggibile.
- Il rischio dei portali è leggibile e il viaggio rimane volontario. La transizione mostra quest, loot, armi, Art e scelte pendenti. Puoi scegliere una ricompensa di fine piano prima di attraversare.

## Animazioni, superfici e segnali

- Usa Re Goblin G come riferimento prioritario per il tratto Expressive Ink. Mantieni profondità leggera V5, silhouette leggibili, ombre tratteggiate e luce localizzata. Riusa le tavole canoniche. Separa pietra, campi, fango, acqua e metallo runico con texture coerenti anche sulle armi e sugli oggetti.
- Per ogni creatura e personaggio crea riposo, camminata, corsa, preparazione, esecuzione, recupero, ferita, sbalzo e caduta. Disegna appoggi alternati, mantelli e peso credibili. Usa un ancoraggio comune ai piedi, uno scarto coerente nella corsa e mani allineate alle impugnature anche cambiando direzione.
- La finestra del colpo e il segnale a terra corrispondono all’hitbox. Distingui schivata, impatto, scudo, clash e colpo mancato con animazione, suono e particelle. I corpi sbalzati seguono una traiettoria visibile e i ripari limitano la spinta. Controlla la resa in movimento a scala di gioco. Verifica scene affollate, sei giocatori e mobile con profilo prestazioni misurabile.
- Tieni Obser e Luna di Vaitern canonici. Mostra separatamente pietra verde, gemma, pergamene e arma. Ogni frammento lunare vale 60 Obser. Per i drop rari scegli segnali distinti e leggibili sullo sfondo.

## Combattimento e build

- Parti dalla concatenazione di scatto, controllo e attacco di Wizard of Legend. Da Dead Cells ricava l’identità delle armi e le finestre di preparazione e recupero. Da Streets of Rogue ricava tattiche leggibili come distrazione, furtività, rumore e agguato.
- Da Hades e Slay the Spire ricava le offerte che fanno cambiare piano d’azione. Da Noita ricava reazioni coerenti tra ambiente, materiali e magia. Trasforma questi principi in effetti propri di Oculum legati a Art, pergamene, Sigilli, armi, ripari e mostri. Una combinazione deve cambiare il modo di mirare, muoversi o scegliere una strada.
- Il Fabbro porta ogni arma fino al rango 12. Spada e scudo al rango 12 usa una Riposta semicircolare a portata doppia e può sbalzare fino a 12 metri. Le Art vengono dal catalogo di Oculum, conservano il tema e si adattano ai tempi reali. Alcuni eroi hanno un’Art fissa. Le Open e le abilità normali restano distinguibili. Ogni partecipante ha la propria Luce e Ombra, con le sue capacità e una frequenza che sale con la difficoltà.
- Pyrel ha una sola Fiammela sentinella immateriale dietro di sé. Si orienta e spara palle di fuoco ai nemici. Quando Pyrel subisce un colpo letale, la Fiammela entra in lui e lo rialza con un’esplosione di fiamme a 360 gradi. Verifica lo stesso comportamento per l’ospite online e il consumo una sola volta per run dopo salvataggio, rientro o ritrasmissione.

## Consegna e prova

- Prova da Gioca subito il seed 251. Mostra il primo bivio e due percorsi verificati. Prova cambio piano, ritorno, salvataggio, caricamento e percorso ai tre atti.
- Con due client autenticati, verifica scoperte condivise, barriere aperte da un ospite, ricompense assegnate una volta, Luce e Ombra per ogni giocatore, presa di Baghest e resurrezione di Pyrel. Ripeti separatamente la prova di carico a sei.
- Mostra una breve cattura presa dal renderer con camminata, corsa, attacco, sfondamento e sbalzo. Riporta ritardi d’input, hitbox, leggibilità e cali di frame emersi nella prova. Indica gli aspetti ancora da rifinire e fornisci i pacchetti verificati del commit compilato.
