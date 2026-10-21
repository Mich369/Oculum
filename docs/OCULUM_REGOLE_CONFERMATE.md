# Oculum — registro delle regole confermate

Ultimo aggiornamento: 20 ottobre 2026. Documento da consultare prima di modificare il regolamento.

## Conferme successive — aberrazioni e penetrazione

- Aberrazioni d’oro e marmo: Minore = Mostro a due fasi; Intermedia = Mini Boss a due fasi; Maggiore = Boss a due fasi; Superiore = Boss a tre fasi. Varianti Solare (glass cannon, elemento Sole) e Angelica (equilibrata, elemento Luce). Le basi esistenti 20/40/60 e il piccolo surplus angelico restano; per le nuove Superiori è scelto un valore iniziale modificabile 80/82.
- Le prime due fasi usano la stessa barra, passaggio al 50% Vita. Solo la Superiore, alla prima sconfitta, entra nella terza fase recuperando il 75% della Vita massima e ricevendo +2 × livello Danni. Passaggio e risveglio non si ripetono per messaggi duplicati; lo stato è persistente nel JSON.
- Raggi multipli: Minori due bersagli; Intermedie tre con +25 Danni; Maggiori sei con +80 Danni alla forma completa. Per le Superiori si conserva il profilo a sei raggi come base modificabile. Le forme precedenti hanno bonus ridotti.
- Oltre Difesa, Oltre Scudi e percentuale aggiuntiva ai danni sugli Scudi sono parametri del singolo colpo sul bersaglio, consumati con il colpo; non cambiano le impostazioni permanenti della vittima. Nuove tecniche individuali con penetrazione hanno CD 2–5 turni; quelle con Oltre Difesa e CD 2 partono scariche.
- Online la turnistica del Master sostituisce la fonte locale di turni e bersagli del player finché collegato. La turnistica locale resta salvata per il ritorno offline.
- Riconfermato il 21 ottobre 2026: online si usa la turnistica del Master della stanza, non una turnistica manuale separata del player. Lo scontro attivo del Master si pubblica automaticamente; «Pubblica» resta disponibile per un invio esplicito e «Chiudi player» conserva la possibilità di interrompere la pubblicazione. Richiesta schede e invio realtime devono funzionare anche senza amicizia fra i tag. Un tag già appartenente a un altro account non viene riassegnato automaticamente: account originale o copia esplicita con nuovo tag, mantenendo l'originale.
- Il Master conserva la possibilità di agire sulle schede online condivise nella propria stanza; le modifiche autorizzate vengono riportate al proprietario. I controlli sulla proprietà del tag non devono impedire queste operazioni del Master e non trasferiscono la proprietà del personaggio.

## Conferme del 20 ottobre 2026 — emblema, mercanti e Open

- Nei tre pannelli di combattimento non compaiono skill in cooldown o senza risorse per alcuna forma; se almeno una forma è utilizzabile la skill resta visibile e la scelta contiene le sole forme disponibili. I sottotratti come tiri rimangono utilizzabili.
- Le Open mancanti dei mostri vengono completate con un'ultimate che aggiunge al danno base 1d50+25 nei gradi iniziali; i profili più forti crescono da 1d90+60 fino a 1d250+400. Sono valori iniziali modificabili, scelti nel bilanciamento delegato. Sblocco al massimo livello richiesto dalle altre tre forme; Buff Open @Stats+4 (più alto per i gradi maggiori) e capacità ridotta con recupero autonomo di tre turni. Le Open e gli effetti già personalizzati non vengono riscritti.
- Emblema di evocazione dell'alchimista: slime per l'intero fight con **120 HP**, fino a **tre** destinatari scelti (anche se stessi), **+3 a ciascuna delle quattro statistiche e +2 a tutti i sottotratti**. L'utente autorizza il prezzo e richiede che sia maggiore di Pawn: valore iniziale modificabile **200 Obser**, Pawn 100. La Vita dello slime è una riserva condivisa; l'assorbimento riusa il percorso dei Guardiani dopo le difese personali. Non ottiene la rigenerazione di Pawn. Bonus temporanei mentre è vivo e rimozione a fine scontro. HP, bonus, destinatari e durata personalizzata sono salvati nel JSON.
- Ogni mercante ha prezzi leggermente diversi: impostazione ordinaria scelta ±5%. Per nuovo negozio, **3%** di probabilità di aumentare i prezzi del **25%**; **1%** di ridurli del **15%**, senza dichiarare il modificatore. La percentuale è persistente: riaprire, cercare, filtrare e ricaricare non ritirano i prezzi. Arrotondamento per difetto, minimo 1 Obser. Il Segno del Chaos usa quanto effettivamente pagato.
- Catalogo Master nell'inventario: filtri combinabili per Grado e categoria (armi, armature/vesti, scudi, oggetti, consumabili, cibo/bevande, materiali, scroll e compagni/evocazioni). Gli oggetti ibridi possono appartenere a più categorie. Nessuna modifica agli inventari o ai requisiti.
- La singola Open usata viene nascosta da Attacco, Difesa e Supporto e utilità fino al prossimo Riposo Lungo. Dato personale alla scheda, persistente. Le eventuali skill della Open mantengono il proprio comando e recupero.
- L'Open attiva il proprio Open Buff. Gli editor offrono una scelta semplice della collocazione nei pannelli; gli effetti avanzati restano chiusi fino al clic. La collocazione conserva tipi/elementi, parser e JSON. Buff e debuff restano anche in Supporto secondo la conferma precedente.

## Equipaggiamento del Fabbro — conferme e implementazione del 20 ottobre 2026

- Ogni arma, armatura e scudo di catalogo indica il proprio livello. Il livello della skill dell'oggetto non può essere inferiore al livello dell'oggetto; ogni forma può avere un requisito più alto. La skill è utilizzabile solo quando il personaggio raggiunge il requisito e ha l'oggetto equipaggiato. Il requisito viene controllato nel pannello rapido, nell'editor e al momento dell'attivazione, anche se la UI è obsoleta.
- Un oggetto di grado superiore a quello del personaggio non è acquistabile. Gli oggetti dello stesso grado o di grado inferiore sono acquistabili, anche se il personaggio non ha ancora il livello per sbloccarne la skill.
- Minimo prezzo equipaggiamento: Grado 0 50 Obser; ogni grado aggiunge 70, quindi Grado I 120, II 190, III 260, IV 330 e così via. Il minimo del Grado III è 260 Obser. La fascia di livello base è 5 × grado; ogni livello oltre tale fascia aggiunge 10 Obser. Le statistiche possono alzare ulteriormente il prezzo. Questi minimi e formule sono impostazioni iniziali del negozio, non impediscono la personalizzazione dei prezzi.
- I bonus statistici degli equipaggiamenti restano 1–3 punti per livello e sono memorizzati nel JSON. Nuove armi del Fabbro includono Stocco dell'Eco Riflessa (1/4 Riflessi), Martello della Faglia (1/3 Forza), Lancia della Soglia Velata (1/5 Velo) e Pugnale della Misura Esatta (1/4 Precisione). Sono aggiunte anche una corazza e uno scudo con livelli e skill difensive. Le frazioni si attivano soltanto usando il relativo sottotratto e il testo rimane modificabile.
- Testi, livello, grado, bonus, skill, forme, costi, cooldown e formula restano modificabili/salvati nell'oggetto; gli equipaggiamenti già salvati mantengono i loro valori. Il livello degli oggetti legacy senza campo `livelloOggetto` rimane 0 per non alterare i salvataggi.

## Accesso online — conferme del 19 ottobre 2026

- Ospite protetto tramite Supabase, senza registrazione obbligatoria. Email facoltativa nelle Impostazioni, collegabile all’ospite mantenendo la sua identità.
- Accesso online (riconfermato il 20 ottobre 2026): il Master deve accettare ogni nuovo utente. La stessa identità già approvata nella stessa stanza può rientrare senza nuova richiesta, salvo revoca o espulsione. Il codice e il QR individuano la stanza e non autorizzano l'accesso; un ospite che perde la sua identità è un nuovo utente.
- Account utilizzabile su più dispositivi; chiedere se mantenere l’accesso sul dispositivo. L’offline resta disponibile senza account e il login non sovrascrive i salvataggi locali.
- Il Master deve essere autorizzato anche dal backend. Per l’avanzamento delle implementazioni e le verifiche distinte consultare `ONLINE_AUDIT_2026-10-19.md`; le parti ancora in prova non costituiscono consegna completata.

## Mostri e organizzazione — conferme del 19 ottobre 2026

- Costrutto Rinsecchito, base Grado 0–I: Res 2, Vol 3, Mat 1 crescente, Ocu 3. Tank con scudi; Ricordo Vitale dura Oculum turni e costa 1 Oculum per turno. Attacco +4/+12/+34 più Oculum, seconda forma ×1,5 e terza ×2. Drop nucleo rotto debole fascia 0–III, rami e cuore raro. Il cuore cura il 90% Vita e dà Ricordo Vitale per 1d9 turni.
- Larva Bianca, base Grado 0–I: Res 1, Vol 2, Mat 0, Ocu 0. Mosse gratuite a cooldown. Assalto +5/+15/+45 più Oculum ×1/×1,5/×2. Nidiata 1d100 / 1d200+20 / 1d250+100 larve con 1 Vita, sacrificate una per danno. La riserva compare come barra Vita rossa sotto la Vita del personaggio; dopo Scudi e HP temporanei assorbe un danno per larva. Scavata: fuga su Velo oppure attacco con svantaggio alto. Un 20 sul Drop dà una scroll Nidiata; l'apprendimento dalla scroll resta raro e non automatico.
- L’utente autorizza la scelta di cooldown e potenza dello svantaggio, purché modificabili. I valori iniziali del catalogo sono riportati nel manuale come impostazioni modificabili, non come ulteriori conferme numeriche.
- Schede organizzabili in cartelle/sottocartelle rinominabili, con menu alla pressione prolungata e spostamento libero. Gli identificativi e gli indici fisici delle schede non devono cambiare per organizzare la barra laterale.
- Se evochi un Occhio dei Caduti mentre il suo proprietario è già nella turnistica, la creatura entra automaticamente nello stesso scontro: offline viene aggiunta localmente; online il proprietario invia la scheda e richiede al Master l'inserimento autorizzato.
- Clone d’ombra: la creazione diretta produce una scheda alleata con le statistiche del proprietario tranne Resilienza, 10 Vita e durata pari ai turni di Oculum. La scroll Ombra viva usa invece Vita pari a 5 × livello del proprietario, copia le altre statistiche tranne Resilienza e dura `grado della scroll × 2 + 3` turni. Se il proprietario è già in turnistica, la scheda del clone viene aggiunta allo scontro: offline localmente; online viene inviata al Master, che ne autorizza l’ingresso nella turnistica condivisa.
- Nella schermata iniziale gli occhi seguono il puntatore anche mentre si premono i controlli. Passando sul ruolo Master, gli occhi orientano lo sguardo in direzione opposta al puntatore.

## Fonti e precedenza

1. Correzione esplicita più recente dell'utente, registrata qui con un esempio.
2. [Manuale integrale consultabile](manuale-consultazione.md), esportato dal manuale interno `lib/src/main/oculum_manual_sections.dart` con `dart run scripts/export_manual_reference.dart`.
3. Codice e test indicano il comportamento implementato: non dimostrano da soli che una regola sia corretta.

Non considerare questo registro la prova che ogni regola è già implementata e verificata. Per l'esito della patch consulta il suo rapporto di verifica. Non inventare regole mancanti: chiedi all'utente, registrane la risposta e aggiungi esempi e test.

## Conferme del 18 ottobre 2026: attacco e difesa

**Arrotondamento generale confermato:** normalmente per difetto. Una regola può dichiarare un'eccezione: la Difesa ×1,5 del quasi riuscito arrotonda per eccesso. Non estendere automaticamente questa eccezione ad altri valori.

Indichiamo con A il totale del tiro d'attacco e con D il totale del tiro difensivo. La Difesa numerica della scheda è una grandezza distinta da D.

| Difficoltà | Quasi riuscito | Pieno ordinario | Evitato ordinario |
|---|---|---|---|
| Facile | A − D da 1 a 6 | A − D da 7 in su | A ≤ D |
| Medio/Normale | A − D da 1 a 5 | A − D da 6 in su | A ≤ D |
| Difficile | A − D da 1 a 3 | A − D da 4 in su | A ≤ D |
| Oculum | A = D oppure A = D − 1 | A > D | A ≤ D − 2 |

Quasi riuscito: la Difesa numerica contro quel colpo vale ×1,5, **arrotondata per eccesso** (conferma dell'utente: Difesa 7 → 11). Il danno base non viene dimezzato. La durata degli effetti in turni/azioni è dimezzata, arrotondata per difetto, minimo 0: 1 diventa 0, 3 diventa 1, 6 diventa 3. Un effetto con durata risultante 0 non viene applicato; 0 non significa durata infinita.

Esempio Oculum, D=10: A=9 o 10 quasi riuscito; A=11 pieno; A=8 evitato.

### Critico positivo da tiro doppio

- A almeno doppio di D: critico positivo dell'attacco.
- D almeno doppio di A: difesa critica positiva e una reazione gratuita contro chi ha provato a colpire. Il log deve dire **«reazione gratuita su chi ha provato a colpirti»**; il contrattacco è critico.
- Esempio confermato: A=4, D=8 dà la reazione gratuita al difensore.
- Il raddoppio del danno riguarda **solo il bonus critico**, non il danno totale. Il critico interagisce con gli stadi di resistenza/Fragilità secondo il manuale.
- L'eccezione del critico da tiro doppio ha precedenza sulla fascia ordinaria del quasi riuscito.

Bonus critico ordinario ricevuto, in base al livello L del nemico:

| Difficoltà | Bonus ordinario | Bonus nel critico da tiro doppio |
|---|---|---|
| Facile | 3 × L | 6 × L |
| Medio/Normale | 2 × L | 4 × L |
| Difficile | L | 2 × L |
| Oculum | L diviso 2, per difetto | doppio del bonus ordinario già arrotondato |

Esempio: 51 danni base, nemico livello 10, Medio: bonus ordinario 20; tiro doppio → 51+40=91 prima di Difesa, resistenze e Scudi. Non 102.

### Online e offline

- Compatibilità di rete: Windows, browser e dispositivi mobili devono comunicare tra Wi‑Fi, rete mobile, Ethernet, VPN e reti che non consentono WebSocket, usando l'autenticazione e le autorizzazioni della stanza. Realtime resta il trasporto immediato; quando il WebSocket non si apre, invio e ricezione passano al registro persistente HTTPS già protetto da RLS. La consegna della scheda si considera completata solo con la conferma `sheet_received_ack` del destinatario; un semplice invio accettato dal server non equivale alla ricezione. Offline continua a funzionare localmente. Le reti senza accesso a Internet o che bloccano anche HTTPS non possono sincronizzare finché la connessione non torna.
- Conferma del 18 ottobre 2026: il danno al partecipante selezionato, dopo il confronto dei tiri, passa per Difesa, Scudo Oculum, Scudo normale, HP temporanei e infine Vita. Il quasi riuscito mantiene la Difesa ×1,5 arrotondata per eccesso; un attacco evitato non consuma protezioni. Restano le eccezioni esplicite già definite per abilità, Resistenza, Scudo di Salvataggio e Pawn. Un duplicato della stessa risoluzione non applica di nuovo il danno.

- Online, in una turnistica, scegli il bersaglio e il tiro d'attacco. VC è il tiro ordinario; Schianto, Forza, Riflessi o altri tiri alternativi richiedono una descrizione e una motivazione al Master.
- Il log del bersaglio richiede una difesa con CM, Riflessi, Resistenza o Manifestazione del Potere, secondo la mossa. Non pubblicare statistiche nascoste per calcolare probabilità.
- La sessione online dichiara tutte le proprie schede, non le copie ricevute. Perciò, passando da una propria scheda all'altra, una richiesta di attacco resta valida anche prima del completamento dell'aggiornamento Presence. Se il bersaglio è già nella turnistica selezionata, può ricevere la richiesta anche quando il token dell'attaccante arriva un istante dopo nel suo snapshot.
- Master e Co-Master hanno lo stesso registro in sola lettura delle schede dei partecipanti nella turnistica. Dal partecipante possono aprire «Apri scheda»; la condivisione non trasferisce proprietà, né abilita un player a modificare la scheda di un altro player.
- Offline le abilità devono continuare a funzionare. Scelta del bersaglio, tiro difensivo ed esito possono essere manuali, senza autorizzazione del Master online.
- Gli effetti su un nemico non devono diminuire per errore le statistiche di chi li attiva.
- Conferma del 19 ottobre 2026: una skill ad area divide il danno totale fra i colpi/bersagli scelti; ogni quota è arrotondata per eccesso. Ogni bersaglio effettua la propria difesa e applica le proprie resistenze. Se una forma richiede più colpi di quanti bersagli distinti sono scelti, i colpi mancanti si assegnano casualmente fra i bersagli selezionati; uno stesso bersaglio può ricevere più colpi. Costo e cooldown si applicano una sola volta all'azione.
- Conferma del 19 ottobre 2026: la generazione casuale assegna a ogni mostro non-NPC e non Pawn una tecnica multi-bersaglio equilibrata oltre a una variante individuale. Le tecniche generate sono persistite nella scheda e restano modificabili dall'editor.

## Conferme precedenti da conservare

- Vita massima: Resilienza × (10 + 5 × Grado). Le statistiche di base del mostro non devono essere conteggiate come punti guadagnati salendo di livello. Un Mostro guadagna 9 punti per livello aggiuntivi alla base.
- Costi: `5/5` è un esempio di costo fisso, non il costo universale. Un intervallo `1/5` ha senso quando l'investimento aumenta realmente danno, difesa, durata, statistiche o altro effetto dichiarato. Le passive non devono richiedere una spesa attiva fittizia.
- Le tecniche hanno un'identità concreta; evitare descrizioni generiche come «attacco tematico». Conservare identità, statistiche, drop e personalizzazioni dei mostri.
- Le pergamene possono essere apprese: devono avere costi e cooldown utilizzabili anche come skill apprese. Non clonare ogni tecnica in ogni elemento.
- Nei Libri Runici, le parole conosciute permettono di inventare skill. Le parole composte generano una Rune Art usabile; le skill si scrivono con il Master, concordando costi, DT, durata, bersagli ed effetti.
- Pawn protegge la Vita dopo gli Scudi del protetto. Si deve contare anche la Difesa del Pawn e scrivere chiaramente nel log chi prende danno e quanta Vita perde. Lo Scudo di Salvataggio blocca l'overflow del colpo che esaurisce l'ultimo Scudo, poi si disattiva.
- Luna e Sole sono nemici. La grafica dei temi è decorativa e coerente con l'elemento; non deve cambiare la disposizione dei tasti o coprire testi e zone cliccabili.

## Larva Bianca — conferma del 18 ottobre 2026

- La modalità fuga di **Scavata** usa il sottotratto **Velo** (`velo`). Questa indicazione riguarda la fuga; non cambia il tiro della modalità di attacco sotterraneo.
- Fonte: correzione esplicita dell'utente «il tiro per la fuga della larva deve essere su velo».

## Nidiata — barra e scroll, conferma del 20 ottobre 2026

- Infestazione mostra una barra Vita rossa pari al numero di mini larve generate. Ogni larva ha 1 Vita e viene sacrificata per assorbire un danno dopo Scudi e HP temporanei; il danno rimasto prosegue verso il personaggio.
- La stessa barra e lo stesso assorbimento si applicano a chi apprende Infestazione con una scroll: è un esito raro secondo le probabilità già previste per apprendere una tecnica da scroll. Usare una scroll esegue la tecnica e la consuma; l'apprendimento non è automatico.
- I nove ranghi della scroll Nidiata hanno questi dadi e modificatori, aggiungendo il Livello dell'utilizzatore: I `1d50+20+livello`; II `1d100+30+livello`; III `1d120+50+livello`; IV `1d200+60+livello`; V `1d200+100+livello`; VI `1d250+120+livello`; VII `1d250+150+livello`; VIII `1d250+200+livello`; IX `2d250+200+livello`.
- Una nuova nidiata sostituisce quella precedente. Le larve e la Vita residua sono salvate nella scheda e incluse negli aggiornamenti online della Vita.

## Pergamene — aggiornamento del 18 ottobre 2026

- Usare una pergamena esegue la tecnica e consuma un esemplare; non assegna automaticamente una skill permanente. Il consumo avviene anche se il tiro fallisce.
- Apprendimento separato: resta necessario 20 naturale e totale almeno `30 + 10 × grado`. Solo allora si effettua un controllo percentuale: Facile 20%, Medio 15%, Difficile 10%, Oculum 5%.
- La scelta delle percentuali è delegata dall'utente. Il 20% precedente viene mantenuto in Facile e ridotto progressivamente nelle difficoltà maggiori. Un doppione non genera una seconda skill. La skill appresa mantiene costi e cooldown e non è evolvibile.
- Colori delle abilità nella barra combattimento: Oculum usa il colore Oculum personalizzato; Resilienza verde, Volontà rosso, Materia blu. Il colore dipende dalla risorsa, non dalla categoria Attacco/Difesa/Supporto.

## Dettagli da chiedere prima di introdurre nuove regole

### IA dei mostri — conferma del 18 ottobre 2026

- Il mostro agisce con l'IA quando il Master passa il suo turno senza avere compiuto azioni per quel mostro. Un'azione già effettuata manualmente impedisce un secondo intervento automatico a fine turno.
- Correzione più recente: **nessun debito sul prossimo turno**. Ogni creatura ha una Reazione, salvo Skill che ne concedano altre. Le Reazioni si ripristinano a ogni nuovo turno proprio senza accumularsi. L'IA può usare una Reazione ancora disponibile prima del ripristino, invece di sprecarla; non ne crea altre e non ne sottrae al turno seguente.
- Questa è una regola confermata; la sua presenza nel registro non certifica che il nuovo gestore IA sia già implementato.

- Eccezioni specifiche di una tecnica alla scelta del tiro difensivo.
- Effetti senza durata, multibersaglio e condizionali non descritti dal manuale: non assegnare valori o condizioni arbitrarie.
- Confronti di raddoppio con totali nulli/negativi: non introdurre premi infiniti o catene automatiche; chiedere la regola se il caso deve essere regolato diversamente.

## Come aggiornare il riferimento

Registra la nuova conferma con data, esempio e fonte. Aggiorna il manuale interno; riesporta il manuale consultabile; aggiungi test sui limiti della regola. Non cancellare una decisione precedente senza indicare quale nuova decisione la sostituisce.

## Conferma del 19 ottobre 2026: Maestria iniziale

Le soglie dipendono esclusivamente dai punti ottenuti tramite Maestria, non dai punti base, manuali o dai buff. Sottotratti: 100, 200, 350, 500, 700, 850; dopo sei punti guadagnati la soglia resta 1000. VC, CM e Aiuta compagno: 250, 500, 750; dal quarto punto 1000. Iniziativa: 200, 400, 600, 800; dal quinto punto 1000. L'avanzo si conserva. Le difficoltà mantengono i diversi guadagni EXP per tiro; non modificano queste soglie. I salvataggi precedenti non contengono il conteggio separato: si preservano valori e progresso, iniziando il nuovo contatore da zero senza attribuire aumenti retroattivi al caricamento.


## Richieste e correzioni del 19 ottobre 2026 — turnistica e titoli

Questo registro conserva le richieste; non certifica la loro implementazione. Le regole successive dell'utente devono essere aggiunte qui prima di applicarle. I punti ambigui restano da chiarire.

### Combattimento, aiuto e bersagli

- Per un attacco alternativo a VC basta descrivere e motivare l'attacco **a voce** al Master. Scrivere è facoltativo e non deve bloccare il tiro né la consegna online.
- Aiuta compagno permette di scegliere il destinatario; il totale, anche negativo, diventa rispettivamente un + o un − nel suo tiro. Cura e supporto devono scegliere i bersagli della turnistica, includendo «Se stessi» quando appropriato.
- Ogni attacco deve avere una fascia di bersagli/colpi modificabile. È possibile selezionare più volte lo stesso nemico. Se si selezionano meno destinatari del numero richiesto, i colpi rimasti si distribuiscono casualmente fra quelli selezionati, anche se il destinatario è uno solo. Costo e cooldown non vengono pagati per ogni colpo.
- Negli attacchi a più bersagli si divide soltanto il danno base; ogni bonus piatto esplicito, per esempio «Danni +8», si applica per intero a ciascun bersaglio. Ogni quota base si arrotonda per eccesso, poi si aggiunge il bonus individuale.
- Anche cure, effetti, difese e supporti possono avere più destinatari. Il riconoscimento deve funzionare sia per effetti strutturati sia per parser del testo.
- Si possono concedere reazioni ad altri. La propria scheda è verde, gli alleati azzurri, i nemici rossi.
- Online le azioni riguardano solo il proprio fight; deve esistere una funzione esplicita per unire più fight. Offline resta possibile la gestione manuale intuitiva.
- Attacchi senza skill usano i Danni inflitti della scheda. La risoluzione deve rispettare Difesa, resistenze per tipo, Schivata Oculum, Scudi, HP temporanei e Vita, anche online. Migliorare il collegamento del vampirismo con danni realmente inflitti e turnistica.
- Nascondere inizialmente le probabilità. Percezione o Investigazione sono azioni lanciabili anche senza bersaglio; scegliendo un partecipante, il totale deve raggiungere **Livello + Velo** usando Oculum per rivelare livello esatto e probabilità. Se manca di al massimo 5, mostra una stima con livello più basso ma stesso Grado; se manca di più, mostra solo «Non senti abbastanza». Mostrare nei Tiri e azioni il migliore dei due tiri. Un critico scopre il punto cieco per sé e alleati: richiesta di attacchi «semi letali», il cui effetto preciso e durata sono **da chiarire**.
- Precisazione successiva confermata: **pari basta**. In caso di lettura approssimata il livello percepito si riduce dello scarto del tiro, minimo 0, conservando il Grado. Esempio: livello 12, Velo 5, tiro 14 → scarto 3, livello percepito 9; tiro 17 → esatto. L'azione Percezione deve offrire sia la scelta di una persona sia il lancio libero senza bersaglio.
- Le skill dei titoli comprendono Open, skill della Open e skill conferite dal titolo stesso. Molte skill iniziali dei mostri vanno rese disponibili dal livello 0, preservando le eccezioni intenzionali.

### Slot e categorie di titoli

- Apprendimento: **1 slot fin dall'inizio + 1 per Grado**. Con Rebirth i primi tre titoli Evoluti non occupano slot. Provengono da addestramento, Maestria o critici.
- Standard: sei iniziali, sette al Grado III, otto al VI, nove al IX (conferma successiva dell'utente).
- Fato: uno alla prima forma della prima skill, uno alla seconda forma della seconda skill, uno alla terza forma della terza skill. Ogni Chained Fate completato concede uno slot dedicato Fato.
- Malanno: uno slot ogni 6 Resilienza. Titoli obbligati non rimovibili volontariamente, non masterabili; a slot pieni possono sospendere un Evoluto. Possibile evoluzione narrativa in Oscuri/Maledetti.
- Benessere: titoli momentanei senza slot, fino al termine della sessione o dello stato positivo; decadono subito con malus gravi, crisi o trauma.
- Alchimia/Magia: slot separati; Rebirth dà uno slot iniziale utilizzabile anche al Grado 0, senza Rebirth uno per aumento di Grado. Massimo equipaggiato pari al Grado, salvo questa eccezione iniziale confermata.
- Chaos: scrivere sempre Chaos. Titoli già Evoluti, bonus forti e punti ciechi forti; uno slot dedicato ogni −10 Karma.
- Attributo: bonus ordinario +1..+3, Evoluto fino +6, Reforgiato +7, entrambi +9, +1 per Grado e crescita statistiche; massimo +12. Tre parole attive dello stesso titolo aumentano il + del 25% (arrotondamento generale per difetto). Un attributo attivabile per livello, massimo 13.
- Attributo del Fato: raddoppia i + ai tiri, massimo +16. Ogni ciclo di 369 giorni offre ai più fortunati fino a 12 slot; con Rebirth la possibilità ricorre ad ogni nuova fase. Non assegnarli automaticamente senza l'evento concordato.
- Leggende: titolo normale una parola di Fato; Evoluto o Reforgiato due parole e una debolezza; entrambi tre parole e due debolezze. Le debolezze danno − pari al +. Se condizioni positive e negative coesistono possono annullarsi o lottare secondo il contesto del Master.
- Lotta delle parole: 9 o 19 dà +; 20 dà + con ulteriore +3 e vittoria automatica alla prossima lotta; 8 o 2 dà −; 1 dà − con ulteriore −3 e prossima sconfitta automatica. Ogni critico comporta tre + o −. Non inventare esiti per le altre facce.
- Le parole possono attivare bonus statistici temporanei per tutto il fight una sola volta, mantenendo riutilizzabile il bonus al tiro. Possono anche rappresentare paura o conseguenze narrative; non tutte le parole evidenziate sono bonus meccanici.
- I titoli Attributo equipaggiati danno Karma pari al proprio +, modificabile dall'interlocutore e dai tratti.
- Chained Fate: dungeon del Fato avviato dal Master, partecipanti espliciti; primi tre completamenti con EXP ×2 e slot Fato, poi EXP ×3 e nessun ulteriore slot premio (conferma successiva). Registrare inizio/fine/completamento per evitare premi duplicati.

### Presentazione e riferimenti grafici

- Pannello cliccabile Titoli indossati, capacità per livello/Grado, Chained Fate completati, informazioni progressive e leggibili.
- Decorazioni minime coerenti per tema, eventualmente occhi animati che seguono il mouse; nessuna sovrapposizione ai testi o perdita di cliccabilità.
- Immagini ricevute il 19 ottobre: home con città gotica e occhio viola; scena arancione con insetti azzurri; vero Sole come enorme occhio luminoso sopra isole volanti. Sono riferimenti artistici e devono restare distinti dalla Luna, nemica del Sole.


### Conferme successive del 19 ottobre

- Confermato: slot standard 6 iniziali, 7 al Grado III, 8 al VI, 9 al IX.
- Confermato: il critico di Percezione/Investigazione scopre il punto debole; sé e alleati applicano Fragilità Semi Letale a quel nemico fino a fine fight.
- Confermato: i primi tre Chained Fate completati concedono slot Fato ed EXP ×2. Dai successivi non si ottengono ulteriori slot premio e l'EXP nei Chained Fate passa a ×3.
- Reputazioni: cartelle e sottocartelle liberamente creabili, senza un limite fisso, per città e luoghi scoperti. Organizzazione salvata nella scheda, senza perdere valori o reputazioni precedenti. È possibile spostare le reputazioni tra cartelle.

### Conferme di combattimento del 20 ottobre 2026

- Percezione, Investigazione, Furbizia e Valutazione possono essere usate per osservare. La scheda propone il valore più alto fra i quattro; il tiro può anche essere lanciato liberamente senza bersaglio.
- Precisione da +6: il colpo ha 80% di avanzare la Fragilità di uno stadio, 15% di due stadi, 5% di tre, senza superare Fragilità Letale. Ogni punto oltre +6 trasferisce un punto percentuale dalla fascia +1 a quella +2 fino a 50/45/5; poi dalla fascia +2 alla fascia +3 fino a 50/40/10. La modifica vale soltanto per il colpo e non cambia la resistenza salvata sulla scheda.
- Da Precisione +20 si ritaglia un ulteriore 5% dalla fascia +1 per un esito speciale che fa ricevere al bersaglio il 260–350% del danno normale, scelto casualmente. Questo esito resta separato dalla progressione delle fasce; la fascia +1 si riduce di conseguenza.
- Schianto: un bersaglio di Grado 0–II colpito salta la propria azione, ma conserva la Reazione e la tira con Schianto +10 contro l'attaccante. Sopra il Grado II questa mossa non nega l'azione.
- Riflessi: con +6 un critico concede una Reazione aggiuntiva contro l'attaccante solo se il movimento dell'attaccante è pari o inferiore al proprio; da +12 il risultato naturale 19 o 20 la concede, da +20 bastano 18, 19 o 20, senza vincolo di movimento. L'effetto aggiunge una sola Reazione per il trigger e non accumula Reazioni oltre i limiti concessi da Skill.
- Concentrazione (statistica almeno 10): un tiro Utility in combattimento con dado naturale maggiore di 10 prepara il prossimo attacco (+10% Danni) oppure la prossima difesa (+12%), consumando il bonus al primo dei due usato.
- Adattamento (statistica almeno 10): un tiro Utility in combattimento con dado naturale maggiore di 10 prepara una riduzione al prossimo danno ricevuto pari a 1 + (dado naturale − 10). La riduzione si consuma sul primo danno e non si accumula oltre il valore maggiore già pronto.
- Schianto contro un bersaglio di Grado 0–II: il colpo riuscito gli fa saltare l'azione, ma conserva la Reazione e la tira con Schianto +10 contro l'attaccante. Sopra il Grado II l'effetto non nega l'azione. La sincronizzazione del salto azione tra dispositivi richiede autorità della turnistica del Master.
- Queste sono regole confermate, non una certificazione che ogni risoluzione offline/online sia già implementata. Conservare costi, durate, bersagli e valori modificabili dagli editor.

### Elementi in combattimento — conferma del 20 ottobre 2026

- Attacco e Difesa mostrano un selettore dell'elemento scelto, sempre visibile prima del tiro e scorribile. L'attaccante sceglie l'elemento del danno; il difensore sceglie l'affinità con cui protegge questa risposta. La scelta difensiva non riscrive resistenze o personalizzazioni salvate.
- Un'affinità che prevale sull'elemento in arrivo riduce del 25% il danno di quell'attacco: Acqua protegge dal Fuoco; Oscuro protegge da Luce/Sacro; Solare protegge da Lunare. Il vantaggio elementale si applica al danno, incluso il bonus del critico, prima delle protezioni e della Vita. L'elemento originale resta quello usato per resistenze e Fragilità.
- Angelico e Diabolico si indeboliscono reciprocamente: ciascuno riduce del 25% i danni dell'altro. Questa protezione vale finché la Vita del difensore è almeno il 30% del massimo; sotto tale soglia svanisce.
- Per gli elementi base, la prima implementazione aggiunge Acqua > Fuoco/Lava, Fuoco > Gelo, Gelo > Vento, Vento > Terra/Radice e Terra > Fulmine > Acqua. Le coppie non elencate, gli elementi personalizzati e i danni Fisico/Taglio/Perforante/Contundente non ricevono vantaggi automatici. La tabella è intenzionalmente circoscritta e può essere ampliata senza cambiare il formato dei salvataggi.
- Regola esplicita: «il Buio batte la Luce per la credenza per la Luna» e «Sole batte Luna»; Angelico e Diabolico sono pari nel senso che si riducono reciprocamente gli attacchi. Conferma utente del 20 ottobre 2026.


### Presentazione confermata durante l'implementazione

- Le immagini consegnate dall'utente sono già artwork IA: possono essere riutilizzate direttamente nella home come riferimenti e scene di Oculum.
- Mantenere ogni superficie coerente con il tema attivo e valorizzare l'occhio, con animazioni leggere e reattive. Non sacrificare fluidità, funzioni o salvataggi. Riduzione animazioni e cliccabilità vanno preservate.
- Test e verifiche finali devono partire dopo aver completato le modifiche, come richiesto dall'utente.

- Conferma successiva: con Rebirth lo slot Alchimia/Magia è utilizzabile anche al Grado 0 (eccezione iniziale al massimo pari al Grado).


### Riserva statistica dei livelli — conferma del 19 ottobre

Ai livelli 5, 15, 25, 50, 100 e 200 si ottengono rispettivamente 2, 4, 7, 13, 25 e 50 punti: un quarto della soglia, arrotondato per eccesso. Confermato dall'utente: riserva da distribuire liberamente, una sola volta per soglia, non un bonus a ogni statistica. I premi già ottenuti restano marcati anche se si abbassa e rialza il livello; nessuna seconda assegnazione caricando il salvataggio.

## 19 ottobre 2026 — Atelier, colori e supporto
- Tema personale con più immagini, ordine dei layer, posizione normalizzata, dimensione, rotazione e opacità. Codice `OCULUM1:` con immagini incluse, importabile senza percorsi locali. Decorazioni in IgnorePointer ed escluse dalla semantica: non intercettano comandi.
- Colori di Resilienza, Volontà, Materia e Oculum personalizzabili nell'Atelier tramite selettore HSV, RGB e HEX. Mantiene i colori precedenti finché non vengono impostati override; ripristino disponibile. Colori opachi per i testi delle statistiche.
- Ritratto della scheda leggermente rettangolare (116×104 desktop, 80×72 compatto), con asset dell'occhio originale già utilizzato nel profilo.
- Contenitore della scheda: «Aiuto e utilità». Comprende il tiro Aiuta compagno, Art/Skill/Titoli di supporto e cura manuale già concordata col Master; nessuna nuova formula di cura introdotta.
- Cure e aiuti usano i destinatari della turnistica corrente online, con conferma di ricezione e protezione dai duplicati; offline applicazione alle schede locali. Il Party apre lo stesso pannello condiviso. I membri annotati solo come testo non diventano automaticamente schede online.

### Riferimento artwork — 19 ottobre
L'utente indica le illustrazioni promozionali anime di S4 League, più curate della grafica del gioco, come riferimento di qualità per nuove immagini originali di Oculum; atmosfera più gotica. Non richiede un sistema di annunci nell'app. Prima immagine generata in Figma: spadaccino e cattedrali sospese, esportata in assets/oculum/home_art/anime_reliquary.png. File Figma: ZooYFl2ORaXAPZks3Jb8B1, nodo 2:2.

## Regole confermate e interventi successivi — 19 ottobre
- EXP a fine scontro: per ogni nemico ucciso, Livello del nemico + somma delle sue statistiche; premio intero a ogni partecipante. Implementati pulsante Termina scontro, reset turnistica e chiusura delle unioni; assegnazione con ricevute contro duplicati. Verifica online reale ancora da completare.
- Cibi di mostri: probabilità di apprendere una loro skill pari a 0,5% + Fortuna in punti percentuali. Esempio confermato: Fortuna 5 → 5,5%. Implementata sui cibi di mostri predisposti dal catalogo, separatamente dal consumo.
- DT della condizione: difficoltà del tiro per liberarsene; durata e DT gestibili dal Master con menu contestuale (destro/pressione prolungata).
- Anima staccata: Svantaggio Oculum per una azione. Il selettore esistente definisce Svantaggio Oculum −12; applicarlo ai tiri Oculum, non alle statistiche permanenti.
- Nuovi buff minori: utente autorizza percentuali e durate contenute e modificabili. Proposta implementata: cinque famiglie (quattro statistiche singole e tutte), stadi I–VI +2/4/6/8/10/12%, 3 turni. Bonus della stessa famiglia non cumulativi; arrotondamento per difetto. 30 cibi/infusi di prezzo crescente collegati ai rispettivi stadi.
- Negozi: materiali con Vitalium sempre disponibile; fabbro armi e Pawn; alchimista cristalli e crafting; chef cibi e bibite.
- Solo alchimista: 1 Ascension Dust per acquisto, prezzo 33–69 Obser, fino a 3. Il periodo Riposo Lungo è mantenuto dal comportamento precedente e va chiarito se richiesto diversamente; nessun raddoppio di potenza assunto dopo la precisazione «1 Ascension Dust».
- Schermata iniziale: solo occhi che seguono il puntatore, alcuni mobili; artwork spostati nella Home.
- Canva: collegamento verificato nuovamente con fetch riuscito del design DAHX-kQUyBo. Nuova generazione avviata; non dichiarare esportata finché il risultato non è scaricato e integrato.

### Stato della rifinitura successiva
- Ambito ribadito dall'utente: Oculum normale (schede, mostri, abilità, negozi e turnistica), non Cammino dell'Eroe. Non trasferire le nuove regole al suo sistema di gioco.
- Integrato il PNG originale consegnato dall'utente «Correzione della mano sulla spada.png» nella galleria Home, senza ulteriori modifiche alle mani.
- Requisiti equipaggiamento: il messaggio mostra il maggiore fra Grado oggetto e Grado richiesto; l'attivazione rapida verifica anche il livello della forma.
- Le Open principali e aggiuntive dei titoli sono accessibili nei gruppi combattimento tramite il comando originale; nessuna seconda applicazione separata degli effetti Open.
- Il log dei nutrimenti indica i turni effettivi, distinguendoli dalle erbe a riposi.
- Il moltiplicatore EXP Chained Fate è limitato ai partecipanti del dungeon.
- Analisi statica `dart analyze lib`: nessun problema. Questo risultato non certifica prove online reali, pacchetti o pubblicazione. Pubblicazione e sostituzione sospese su richiesta dell'utente fino alla rifinitura completa.

## Turnistica online del Master — 19 ottobre 2026
- Online, i turni vengono avanzati dal Master; i player seguono lo scontro pubblicato che contiene la propria scheda. Cambiare PG seleziona lo scontro del nuovo PG, senza unire fight differenti.
- Entra nello scontro condivide la scheda e richiede l'inserimento al Master. La turnistica cambia dopo la conferma nel suo aggiornamento; l'arrivo della scheda in ritardo non perde la richiesta.
- Le schede dei partecipanti aggiornano vita e risorse nella turnistica del Master, preservando ordine, iniziativa e reazioni gestite dal tracker.
- Il progresso personale ricevuto dal Master attiva condizioni, cooldown e avanzamento Art una sola volta. Offline i contatori rimangono manuali.
- In fight, danni, cure, modificatori di Aiuta compagno e condizioni si applicano al destinatario secondo l'esito. Un totale negativo di Aiuta compagno sottrae dal prossimo tiro. Nessun reinvio deve ripetere la mutazione.
- Il log del difensore indica attaccante, mossa, danni dichiarati e DT difensiva uguale al totale del tiro nemico. Restano valide le soglie e le eccezioni del confronto attacco/difesa confermate sopra.
- Cure e condizioni sulle proprie schede non aperte vengono applicate senza cambiare la scheda visualizzata; anche il loro progresso segue i turni del Master.
- Preferenza utente: l'immagine Home si sceglie dalle anteprime sotto la scena principale, con selezione persistente e ripristino dell'originale.
- Nome del pannello: «Supporto e utilità». Ogni abilità che dona/applica buff o debuff compare anche qui, pur restando nelle eventuali altre categorie. Per i potenziamenti misti VC/CM o Danni/Difesa, pari valore comporta presenza sia in Attacco sia in Difesa; altrimenti prevale il valore maggiore.
- Erbe fumabili, solo alchimista: 30–50 Obser. +6 Volontà e +4 Materia fino al primo limite tra 3 turni di combattimento, 2 riposi brevi e 1 lungo. Alla fine Confuso: −20% danni e DT +2 per 2 turni oppure fino alla prossima cura o riposo. Il +2% iniziale è sostituito dalla correzione esplicita DT +2.
- Le scroll presenti in inventario devono comparire nei pannelli Attacco/Difesa/Supporto e utilità secondo gli effetti, collegandosi ai bersagli della fight. L'uso consuma la scroll e mantiene i requisiti e le probabilità di apprendimento già confermati.
- Segno del Fato, solo alchimista: il negozio fissa un prezzo da 50 a 120 Obser; una sola copia per negozio. A 50 le probabilità sono 70% Ispirazione normale, 20% Super, 10% Oculum. A 120 sono 30%/40%/30%, con interpolazione graduale confermata. Consumare un segno assegna immediatamente una delle tre ispirazioni secondo le regole già esistenti, senza duplicare il consumo.

- Correzione utente: Segno del Fato ha prezzo fissato dal negozio, 50–120 Obser, una sola copia nello stesso shop. Segno del Chaos: solo alchimista, presenza 3% per negozio, prezzo 60–120 Obser. Consumandolo, ogni 10 Obser del suo prezzo (per difetto) genera un’estrazione indipendente su Resilienza/Volontà/Materia/Oculum casuale: 75% +1 punto, 13% +2, 9% +3, 3% +0. Punti permanenti; disponibilità e prezzo persistenti.

## Recupero automatico online — 19 ottobre 2026
Richiesta utente: tutte le proprie schede online devono poter arrivare al Master e partecipare alla sua turnistica. Correzione più recente: la connessione, l’arrivo del Master e la richiesta di recupero sincronizzano automaticamente solo la scheda attualmente usata; le copie ricevute non vengono rispedite come proprie. L’ingresso richiesto resta in attesa e viene ritentato finché lo snapshot del Master non contiene il partecipante. La presenza in ritardo non elimina una richiesta: il Master la ricontrolla dopo la presenza o la scheda. Restano verificati proprietario/sessione, campagna e fight pubblicata. Il recupero di una singola scheda usa il suo tag.

- Precisazione utente: invio automatico al Master soltanto della scheda attualmente usata, senza inviare in blocco le altre. Restano conferma di ricezione e ritentativi per la scheda scelta.

## Uso dei sottotratti — 20 ottobre 2026
- Correzione esplicita dell'utente: i sottotratti in sé sono sempre utilizzabili; le soglie di Maestria non sono un requisito per poterli tirare. La Maestria continua a governare i propri avanzamenti e benefici. Nei pannelli di combattimento sono selezionabili i sottotratti pertinenti all'azione, anche se il vecchio campo `unlocked` del salvataggio è falso. Strategia è disponibile anche come scelta difensiva.
- In attacco, Manifestazione del Potere con totale almeno +6 aggiunge +3 danni per livello a ciascun bersaglio colpito; negli attacchi multipli il bonus piatto si applica a ogni bersaglio.
