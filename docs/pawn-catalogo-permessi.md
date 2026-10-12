# Pawn creatura e permessi Follia

## Catalogo delle creature

Cerca **Pawn** nel Monster Book e usa il pulsante **+** per creare una scheda.
La base di livello 0 è Resilienza 3, Volontà 3, Materia 5 e Oculum 0.
Le tre capacità sono passive, senza costo Oculum; non viene inventata un’Oculum Art o una Open.

Nel pannello **Pawn · Guardiani** puoi:

- scegliere una o più schede da proteggere, locali oppure online;
- terminare il turno del Pawn;
- assegnare i punti ottenuti salendo di livello;
- aggiungerlo all’iniziativa senza duplicare il token della sua scheda.

La scheda della creatura e il guardiano condividono Vita e Scudo. Il Pawn non può proteggere se stesso.
Intercetta soltanto il danno che raggiungerebbe la Vita, dopo Difesa e Scudi del bersaglio.
Poi applica la **propria Difesa**, quindi il proprio Scudo e infine la propria Vita.
Per Pawn e Pawn V2, la base è `(Volontà + Materia) / 2`, arrotondata per difetto, più livello e grado × 6.
Il Pawn creatura usa la Difesa totale della sua scheda, inclusi i suoi bonus e malus.
Esempio: Pawn base di livello 0 ha Difesa 4. Se intercetta 11 danni senza Scudo, ne assorbe 4 con Difesa e perde 7 Vita; la scheda protetta non li subisce.
Il pannello mostra la Difesa. Il log indica il bersaglio protetto, danni assorbiti dalla Difesa, Vita e Scudo persi e l’eventuale consumo dello Scudo di Salvataggio.

Ogni turno proprio guadagna 25 EXP e cura 10 Vita; se già al massimo guadagna invece 5 Scudo.
A 20 Scudo ottiene Scudo di Salvataggio: il colpo che esaurisce lo Scudo non intacca la Vita, poi il salvataggio si disattiva.
Ogni livello concede 6 punti. La morte usa il sistema esistente del Nucleo rotto di Pawn, senza duplicare il premio.
Il Pawn e il Pawn V2 acquistati nel mercato mantengono le regole e i salvataggi esistenti.

## Giullare Ossa-Filo e generatore Follia

Il blocco segnalato con 35 schede non era un limite sul numero di schede: il Giullare era fermato dal requisito Follia del party.

- Master e co-Master possono oltrepassare il requisito nel catalogo e nel generatore rapido.
- Per i player il requisito resta attivo. Il catalogo mostra il motivo e disabilita la creazione invece di chiudersi senza spiegazioni.
- La variante usa tutta la larghezza disponibile nel menu.
- I controller del dialogo vengono eliminati dopo la chiusura dell’animazione.

## Test di danno elementale

Il test delle resistenze isola temporaneamente Fortuna con un effetto di test e lo rimuove al termine.
Questo elimina la schivata casuale che poteva falsare il controllo della perdita di Vita su macOS.
La Fortuna dell’app conserva il suo funzionamento.
