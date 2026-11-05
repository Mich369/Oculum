# Direzione degli artwork e ritiro del Ragno — 2 novembre 2026

## Richieste esplicite

- «Ragno degli Obser Falsi: eliminalo dal manuale».
- «procedi col creare immagini ma mostri soprattutto se ostili più mostruosi».
- «è comunque un dark fantasy nonostante le stranezze».
- «qualcosa di più simile a questo come stile», con riferimento allegato `codex-clipboard-191653d3-c889-41c0-989d-c6e42fd34217.png`.

## Adattamento visivo

Il nuovo riferimento precisa la direzione generale delle prossime proposte: disegno anime dark fantasy, ombre profonde, profili espressivi, pennellata opaca e colori controllati. Gli ostili devono apparire mostruosi, inquietanti e minacciosi. Non rendere automaticamente aggressivi i personaggi pacifici già definiti, né annullare le immagini canoniche precedenti.

Il riferimento detta tratto, chiaroscuro e atmosfera; non impone di copiare il ragazzo raffigurato. Anatomia, materiali, ambiente e particolarità di ogni specie restano vincoli. Rame fatato conserva la componente pittorica opaca, senza imporre toni dolci, rame su ogni soggetto o scenari copiati. Restano validi centro leggibile, scene sotterranee senza cielo, Luna assente salvo eccezioni personali e assenza di testo dipinto. Nessuna nuova capacità o statistica viene dedotta dai disegni.

Prime nuove proposte: sei Tempeste Sorridenti, con volto largo e sorriso inquietante nella nube allungata, denti di ghiaccio, filamenti elettrici e arti a vortice che non toccano terra. Il 3 novembre è stato scelto il desktop D — Colonna contorta. La copia canonica coincide byte per byte con la proposta mostrata. [Conferme artwork](CONFERME_ARTWORK_2026-11-02.json).

## Ragno degli Obser Falsi

Ritiro dal manuale/catalogo attivo e dai nuovi incontri tramite lo stesso filtro già applicato a Cuore Filo, anche per le varianti generate. Lookup legacy, dati e personalizzazioni delle vecchie schede conservati. Le sei proposte sono archiviate fuori dalla coda dei voti, non cancellate e non approvate.

Il controllo finale trova anche un generatore indipendente nel minigioco Dungeon: conservava il nome nella lista dei corpi elementali. Applicato il medesimo filtro prima della generazione, mantenendo gli indici originali per non cambiare i modificatori dei mostri successivi. Non cancellare o sostituire gli incontri già salvati.

Implementazione locale e prove vanno distinte dalla distribuzione: i pacchetti verificati della build `2765a5df` restano intatti finché una nuova build non li sostituisce dopo verifica. La scelta artistica non certifica una nuova consegna. Nessuna riga chiusa al 100% senza la procedura di approvazione.

## Verifiche locali

Passati 45 test locali distinti: 6 sul ritiro, 34 su catalogo/personalizzazioni/temi, 4 sul log della versione e 1 su avvio/progressione/copie isolate del Dungeon. Quest'ultimo è una regressione del minigioco, non una prova statistica di tutti gli spawn. Analisi iniziale dei due file pulita; analisi finale con il generatore registrata nel log di lavoro. Sei proposte finali e due iterazioni intermedie conservate, con SHA, PNG/CRC/decompressione e prompt nel [manifest](../output/artwork/dark_fantasy_2026-11-02/manifest.json). Verificati 102 file della coda e 222 collegamenti locali delle due gallerie. Sono prove locali, non una nuova CI, un test grafico indipendente o una distribuzione.

## Personalizzazione

Restano modificabili nell'editor/JSON i mostri legacy salvati, statistiche, Skill, Art, Open, costi, durate, bersagli, effetti e anatomie. I prompt delle nuove proposte sono conservati accanto alle immagini; colori e composizione possono essere rivisti prima della scelta canonica.
