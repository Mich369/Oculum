# Skill dell’Art: conferma, dadi e sei turni

La conferma dell’Art mantiene i controller vivi fino alla fine dell’animazione di chiusura.
Le Skill dell’Art senza costo che hanno effetti con dadi mostrano anch’esse una conferma prima di tirare.
Annullare non consuma risorse e non attiva gli effetti.
Se la forma è già selezionata, **Usa di nuovo la forma attiva** riapre la conferma: non serve spegnerla prima. Si rispettano costi e cooldown; annullare conserva il bonus e il conteggio esistenti.

Esempio verificato: **Aumento/diminuzione statistica → Oculum**, valore vuoto, dado **1d15**, opzioni **Aggiungi Livello** e **Aggiungi Grado**, valore Grado **1,5**.
Il valore vuoto con un dado viene trattato come zero. Il dado viene risolto una sola volta all’attivazione; il risultato entra nel bonus e nel log.
La voce Livello nell’attivazione Art usa il livello della forma attivata; il Grado usa quello della scheda.

Una Skill dell’Art attiva e non passiva mostra i turni rimanenti. Dopo **sei turni personali** torna a **livello 0**; i bonus non accumulabili della sua attivazione vengono rimossi.
Il conteggio viene salvato insieme al livello, anche nel diario rapido di persistenza: riaprire la scheda non deve farlo ricominciare.
Ripetere lo stesso numero di turno non accorcia la durata. I tiri non contano come turni.
Le Skill passive restano automatiche e non vengono spente dal conteggio di sei turni.

Sono modificabili i valori dell’effetto, il dado, la statistica bersaglio, i moltiplicatori livello/grado, la durata del singolo effetto, i costi, il cooldown e il tipo passivo/attivo della Skill.
