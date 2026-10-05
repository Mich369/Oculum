# Catalogo, pergamene, resistenze e tiri

## Animazione dei dadi e descrizioni dei sottotratti

La sagoma del dado ruota di 360 gradi in 900 ms a ogni tiro, anche quando
il tiro apre un nuovo overlay sopra un dettaglio o un dialogo. Il testo del
risultato appare dopo la rotazione e non presenta sottolineature. Le descrizioni
dei sottotratti compaiono dopo 450 ms con il mouse sopra.

Parametri modificabili nel codice: angolo, durata e curva della rotazione in
`lib/src/main/oculum_home_colors_and_base_widgets.dart`; durata prima del risultato
e prima di poter chiudere il tiro in `lib/src/main/oculum_home_combat_progression.dart`;
ritardo della descrizione in `lib/src/main/oculum_reference_sheet.dart`.

`scripts/install_github_distribution.ps1 -RunId <id>` sostituisce la distribuzione
con i pacchetti di una build GitHub riuscita del commit corrente. Le cartelle
`windows` e `windows-test` sono estratte e avviabili; la versione Test ha
salvataggi separati. `BUILD-VERIFICATE.json` riporta commit, build e hash dei file.

## Dove trovarli

- Master → Catalogo completo del Master.
- Inventario e crafting → Catalogo completo del Master (aperto per il Master).
- Resistenze → Cerca elemento; la ricerca include elementi personalizzati salvati.
- Il pulsante dadi apre i tiri nella schermata attuale. L'animazione di ogni tiro appare sopra la schermata, il dettaglio o il dialogo attuale.

## Pergamene

Il catalogo contiene dardi, vincoli e egide per ogni elemento, dal grado 0 al XII.
Un Drop con totale almeno 18 dà sempre una pergamena: 18–27 grado 0,
28–37 grado I, e un grado in più ogni 10, fino al XII. L'elemento e la famiglia sono casuali.

Usare una pergamena richiede conferma e consuma una sola copia, anche quando il tiro fallisce.
Annullare non consuma nulla. La skill usa Volontà, i suoi bonus al tiro,
il modificatore globale, l'Oculum preparato e la difficoltà esistenti.
Un 1 naturale fallisce. I risultati e il testo completo della skill sono inviati al Master online attraverso il normale canale dei tiri.
Il Master conferma i bersagli, i danni ricevuti, il rallentamento e Gelo;
gli effetti sui nemici non vengono applicati al personaggio che usa la pergamena.

Gli effetti sul proprio personaggio sono temporanei e salvati: l'egida dà Difesa,
il vincolo dà vantaggio ai tiri. Riutilizzare la stessa famiglia dello stesso elemento
sostituisce il buff precedente, anche se di grado diverso.
La durata scade con i propri turni; non modifica le statistiche base.

Con 20 naturale e totale almeno `30 + 10 × grado`, un d100 da 1 a 20 permette
di apprendere la skill. Quindi grado I richiede totale 40.
La skill appresa resta nelle Skill, non richiede altre pergamene, non può evolvere,
e la stessa skill dello stesso grado non viene duplicata.

## Valori modificabili

Nelle normali schede restano modificabili oggetti, quantità, nome, note, peso,
elemento, gradi, bonus e proprietà già esposti dagli editor. Il Master sceglie
destinazione locale/online e quantità dal catalogo. Le resistenze per elemento
mantengono preset e percentuale personalizzata anche durante la ricerca.

Le regole delle nuove pergamene sono centralizzate in `lib/src/main/oculum_scrolls.dart`:

| Parametro | Valore attuale |
| --- | --- |
| Primo Drop utile | 18 sul totale |
| Incremento di grado | ogni 10 sul totale |
| Grado massimo | XII, oltre al grado base 0 |
| Valore nominale | 300 × (grado + 1)² Obser |
| Rivendita al mercante | un sesto del valore per copia |
| Dado del dardo | d(8 + 6 × grado) + propri danni |
| Bonus critico contro lo scudo | +20% × grado |
| Bersagli del vincolo | 1 + grado |
| Danni del vincolo | 50% × grado dei propri danni; nessuno al grado 0 |
| Vantaggio del vincolo | +2 + grado ai tiri |
| Difesa dell'egida | +3 + 3 × grado |
| Durata dei buff | 2 + grado dei propri turni |
| Soglia per apprendere | 20 naturale e totale ≥ 30 + 10 × grado |
| Probabilità di apprendere | 20% |

Nomi, descrizioni e parametri delle pergamene sono conservati in `craftData.scroll`.
Le Skill apprese conservano `scrollData`, aggiunto senza cambiare i campi dei vecchi salvataggi.
Le verifiche automatiche coprono soglie, copertura elementi/gradi, compatibilità JSON,
consumo, annullamento, scadenza dei buff e stabilità delle statistiche durante la ricerca.
Non costituiscono una verifica su due dispositivi collegati.

## Pawn

Pawn è acquistabile dal Master nel Catalogo completo per 100 Obser. Parte al livello 0
con 3 Resilienza, 3 Volontà, 5 Materia, 0 Oculum e 30 HP. Si possono selezionare una o più
schede locali o online da proteggere. Il danno viene deviato dopo che il bersaglio ha
consumato i propri scudi, Scudo Oculum, Scudo di Salvataggio e HP temporanei: Pawn interviene
solo sulla quota che altrimenti raggiungerebbe gli HP. I danni diretti da condizioni sono
anch'essi deviati, ma conservano le regole proprie della condizione.

Alla fine di ogni turno Pawn recupera 10 HP fino al massimo di 30; se era già al massimo,
ottiene 5 Scudo. Raggiunti 20 Scudo ottiene uno Scudo di Salvataggio, che si consuma quando
il suo Scudo viene esaurito da un colpo e annulla l'eccedenza di quel colpo. Un turno già
conteggiato non può essere ripetuto; Pawn a 0 HP è inattivo. I dati e i bersagli sono salvati
nella campagna e le richieste online hanno un ID stabile per i tentativi ripetuti.

I valori regolabili di Pawn sono centralizzati in `lib/src/main/oculum_pawn.dart`:

| Parametro | Valore |
| --- | --- |
| Prezzo | 100 Obser |
| Livello iniziale | 0 |
| Resilienza / Volontà / Materia / Oculum | 3 / 3 / 5 / 0 |
| HP iniziali e massimi | 30 |
| Cura per turno | 10 HP |
| Scudo per turno a vita piena | 5 |
| Soglia Scudo di Salvataggio | 20 Scudo |

### Progressione di Pawn

Ogni turno completato concede 25 EXP a Pawn. Ogni livello richiede metà dell'EXP
standard della difficoltà attiva: 500 in Normale (anziché 1000) e 685 in Oculum
(anziché 1369). Ogni livello concede 9 punti statistica, come un Mostro standard;
quindi Pawn raggiunge la stessa crescita statistica con metà EXP. I punti si
assegnano a Resilienza, Volontà, Materia o Oculum. Ogni punto Resilienza aumenta
gli HP massimi di 10 e cura altrettanti HP al momento dell'assegnazione. Livello,
EXP, statistiche e punti non assegnati sono salvati nella campagna.

## Materiali, forgiatura e Mappa degli Occhi — aggiornamento

Il catalogo del Master contiene 75 nuovi materiali: 20 fantasy di grado 0
(Gerin, Velruna, Ambril, Nacrel, Feralis, Lumerba, Sileth, Draven, Mirel, Thornil,
Osserin, Aurvel, Nebrin, Crisol, Tessarin, Virdel, Brumel, Cendril, Rhovan, Elun),
12 varianti fantasy dai gradi I a XII, 32 minerali, fibre e reagenti e 11 componenti di mostri.
Sono presenti 87 nuove ricette: raffinazione, tessitura, equipaggiamenti, distillati,
leganti alchemici e intarsi. Un legante può diventare ingrediente della ricetta successiva.
I materiali e le ricette nuovi sono proposte originali, distinte dai materiali dell’autore.

La forgiatura su un oggetto richiede tutti i materiali indicati nella ricetta,
in grammature positive. Se manca qualcosa non consuma nulla. Consuma soltanto le
quantità richieste e l’eventuale costo Oculum; lavora una sola copia per volta.
Può applicarsi a qualsiasi arma, armatura o scudo. La stessa ricetta non può essere
applicata due volte sulla medesima copia. Nelle Risorse il pulsante apre il ricettario.

Due frammenti di Gerin permettono la Vampata dal menu dell’oggetto. Il tiro sceglie
il maggiore tra Canalizzazione e Manifestazione del Potere sbloccate. Le emissioni
innocue richiedono di superare quel tiro per vedere l’utilizzatore; le dannose
richiedono CM e, se fallisce, infliggono i suoi Danni. Il Master risolve i bersagli.

La Mappa degli Occhi comprende Potenziamenti, Skill, Forgiature e Crafting.
Le voci delle schede e delle ricette sono suggerite mentre colleghi parole nel Diario,
anche dal menu del tasto destro. Nella mappa il tasto destro offre cambio categoria,
cambio stato e cronologia; su telefono puoi usare pressione lunga o Cambia stato.
Gli stati e la cronologia sono salvati come conoscenza personale, senza riscrivere
il testo originale del Diario.

Ogni 10 nuovi collegamenti esplicitamente classificati si tenta un’ispirazione.
Dopo un fallimento ogni nuovo collegamento aggiunge 5 punti percentuali,
fino al limite della difficoltà. La probabilità torna al valore iniziale soltanto
quando si ottiene un’ispirazione. Il tipo è Comune 70%, Super 20%, Oculum 10%.
Conteggio, probabilità e ricompense già valutate sono persistenti; aprire di nuovo
la mappa non premia nuovamente gli stessi collegamenti.

| Difficoltà | Probabilità iniziale | Massimo |
| --- | --- | --- |
| Facile | 50% | 95% |
| Normale | 50% | 75% |
| Difficile | 50% | 60% |
| Oculum | 25% | 50% |

Valori modificabili: nomi, gradi, pesi, tempi, descrizioni ed ingredienti nel catalogo
`lib/src/main/oculum_crafting_expansion.dart`; ingredienti, costo Oculum ed effetti
anche negli editor delle ricette. Negli editor degli oggetti: quantità, peso, note,
statistiche, proprietà e grado. Le percentuali, la soglia di dieci collegamenti e
il bonus di cinque punti sono in `lib/services/oculum_memory_inspiration.dart`.
Categorie e stati sono in `lib/services/oculum_diary_roles.dart`; i ritardi dei dadi
e dei suggerimenti sono descritti nella prima sezione di questo documento.

Ispirazioni per il sistema di combinazione:
- Manuale ufficiale Dragon Quest VIII: https://www.nintendo.com/eu/media/downloads/games_8/emanuals/nintendo_3ds_2/dragonquest8/ElectronicManual_Nintendo3DS_DragonQuest8_EN.pdf
- Materiali di crafting ESO: https://help.elderscrollsonline.com/app/answers/detail/a_id/4001/


### Guanti con lame

- Grado 0: Guanto a lame di goblin, zanne di goblin 200 g + pelle di mostro 300 g; +5 Danni perforanti da equipaggiato.
- Grado I: Guanto runico del Forest Demon, corno di Forest Demon 300 g + metallo runico 700 g; +10 Danni perforanti da equipaggiato.
- Skill del guanto forte: Affondo runico, costo 1 Volontà, Danni +20 perforanti, cooldown 6 turni. Dal menu Skill dell’oggetto viene aperta nelle Art e richiede il guanto equipaggiato e il grado I. Costo e cooldown usano il sistema persistente delle Art.
- Sono modificabili le grammature e i nomi negli editor delle ricette; bonus e grado negli editor degli oggetti; la skill nei normali editor Art. I valori iniziali dei bonus e della skill sono in `oculum_crafting_expansion.dart`.
