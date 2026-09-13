from pathlib import Path
import re, subprocess
p=Path('lib/src/main/oculum_manual_sections.dart')
s=subprocess.check_output(['git','show','HEAD:lib/src/main/oculum_manual_sections.dart']).decode('utf-8')
# Edit the canonical chapters; keep the historical fallback outside this pass.
end=s.index('// Kept as a compact fallback draft')
active,legacy=s[:end],s[end:]
chapters={
1:'''In Oculum il potere passa dagli occhi. Un occhio può custodire un ricordo, portare i segni di un trauma o dare forma a ciò che desideri. Le sue capacità si intrecciano con la storia di chi lo possiede.

La scheda descrive il personaggio attraverso quattro statistiche: Resilienza, Volontà, Materia e Oculum. Le usi in combattimento e nelle altre scene. Prima di tirare, racconta che cosa vuoi fare: se il modo in cui agisci lo giustifica, puoi proporre un uso diverso dal solito della tua statistica.''',
2:'''La Resilienza misura quanto riesci a sopportare: una ferita, la fatica di un viaggio, uno sforzo mentale o spirituale. Da questa statistica dipende la tua Vita massima.

Vita massima = Resilienza × (10 + Grado ×5).

Quando la Resilienza raggiunge valori molto alti, usa queste equivalenze:
• 100 Resilienza = 1 Vera Resilienza;
• 10 Vera Resilienza = 1 Resilius;
• 10 Resilius = 1 Resilium.''',
3:'''Usi Volontà per sostenere un attacco, imporre la tua presenza e continuare ad agire sotto pressione. In una scena può esprimersi come determinazione, forza d’animo o capacità di affrontare qualcuno.

In scheda, Volontà potenzia l’attacco e contribuisce alla Difesa insieme a Materia. Ogni 3 punti aumentano il tiro d’attacco; ogni punto permette inoltre di trasportare 3 kg di inventario.''',
4:'''Materia entra in gioco quando contano il corpo, la precisione e il lavoro delle mani. La usi per forgiare, costruire, maneggiare un oggetto, reggere un impatto o eseguire un gesto tecnico.

Contribuisce alla Difesa insieme a Volontà. Ogni 2 punti aumentano la CM e ogni 5 punti aumentano l’Iniziativa.''',
5:'''Oculum è il potere magico del tuo occhio. Alimenta le Arti e può manifestarsi attraverso magia, percezione, ricordi, rituali o trasformazioni, secondo le capacità del personaggio.

Ogni punto aumenta di +2 la potenza delle Arti. Puoi anche usare Oculum per aumentare il bonus di un tiro, quando riesci a spiegare come il tuo potere interviene nella scena.''',
6:'''Quando sali di livello, guarda quali statistiche hai usato durante la storia. La crescita segue quelle azioni:
• +3 alla statistica più utilizzata;
• +2 alla seconda;
• +1 a ciascuna delle altre;
• +6 Scudo.

Per i tiri che non sono attacco o difesa, il bonus è Statistica / 2 + Livello + Grado ×6.

Per esempio, con Resilienza 20, livello 10 e Grado I tiri 1d20 + 26: 10 dalla statistica, 10 dal livello e 6 dal Grado.

CREARE UN MOSTRO

Nel tutorial e nel Monster Book scegli il livello: il Grado viene calcolato automaticamente con le soglie del capitolo 9. Ogni Grado raggiunto aggiunge punti al totale da distribuire:
• Mostro comune: +10;
• Mini-Boss: +15;
• Boss: +25.

La crescita per livello resta di 9, 12 o 18 punti, rispettivamente. La generazione aggiunge i 3 punti per livello di compensazione dei Titoli già previsti. Un Boss di livello 30, Grado II, ha quindi 30 ×21 + 2 ×25 = 680 punti.

Se il mostro ha almeno una Skill o una Oculum Art, riceve Oculum: Volontà e Materia vengono portate a soglie utili, Resilienza sostiene la Vita e la riserva più ampia alimenta le tecniche. Solo una creatura senza entrambe distribuisce tutto fra Resilienza, Volontà e Materia, con Oculum a zero.

Al livello 0 si redistribuisce il totale delle statistiche base del Book, senza bonus di Grado. Per una creatura con poteri, la base minima è di 4 punti; senza poteri è di 3. I mostri già salvati conservano i propri valori.''',
7:'''Quando risolvi un’azione, questi valori ti dicono cosa tirare e quale soglia superare.

• DT, Difficoltà Tiro: la soglia di un’azione difficile.
• CM, Classe Materia: la soglia da superare per colpire un bersaglio.
• VC, Volontà Combattiva: il bonus principale al tiro d’attacco.

DT, CM, VC, Danno, Difesa, Iniziativa e tiri di statistica contano anche Livello + Grado ×6.

Iniziativa: 1d20 + Materia / 5 + Livello + Grado ×6.
Movimento: 30 + Materia / 6 metri, più gli eventuali bonus @Movimento.

Per il Danno totale somma danno base, bonus dell’arma equipaggiata e Livello + Grado ×6. Se impugni più armi, conta soltanto il bonus della più forte.

La Difesa parte da (Volontà + Materia) / 2 + Livello + Grado ×6. Si aggiungono i bonus Difesa e Scudo degli oggetti equipaggiati che proteggono.''',
8:'''Raggiungi un nuovo Grado quando arrivi alla soglia di livello indicata nel capitolo seguente. A ogni passaggio ottieni +36 Scudo e +1 Scudo Critico.

Puoi inoltre livellare un numero di Titoli pari al Grado raggiunto, scegliendo soltanto quelli già evoluti. Questo passaggio è la riforgiatura: il Titolo riceve una nuova quest, può sviluppare nuove Skill e prosegue in una forma legata alle tue azioni e a ciò che vuoi ottenere.

Per i punti statistica dei mostri usa il bonus del loro tipo: +10 per comune, +15 per Mini-Boss e +25 per Boss a ogni Grado.''',
9:'''Leggi la colonna normale per un personaggio o un mostro senza Rebirth. Se hai effettuato il Rebirth, usa la seconda soglia. Sotto la prima soglia sei Senza Grado.

• Grado I — livello 10 / Rebirth 8
• Grado II — livello 30 / Rebirth 20
• Grado III — livello 40 / Rebirth 30
• Grado IV — livello 50 / Rebirth 40
• Grado V — livello 60 / Rebirth 50
• Grado VI — livello 70 / Rebirth 60
• Grado VII — livello 80 / Rebirth 70
• Grado VIII — livello 90 / Rebirth 80
• Grado IX — livello 100 / Rebirth 90
• Grado X — livello 120 / Rebirth 110
• Grado XI — livello 150 / Rebirth 130
• Grado XII — livello 200 / Rebirth 190

Per esempio, un mostro di livello 29 è di Grado I. Al livello 30 passa al Grado II; il Grado III arriva al livello 40.''',
10:'''Una volta al giorno puoi richiamare il potere di un Titolo del Fato evoluto. Scegli un momento in cui il significato di quel Titolo riguarda ciò che stai facendo.

Puoi aumentare il tiro di +1d10 oppure ottenere un Critico spirituale: dopo aver completato un tiro molto difficile, lo trasformi in un critico assicurato con ritiro.

Il Titolo resta fissato al personaggio, ma perde temporaneamente l’evoluzione per 9 ore.

Per esempio, [Saikai, L’Ultima Risorsa] riguarda la dedizione a finire ciò che si è iniziato. Può sostenere un ultimo atto anche da morto, per portare a termine il compito e raccoglierne i frutti.''',
11:'''Somma i bonus percentuali prima di applicarli al valore di partenza.

Con +50% e +25% ottieni un unico bonus del 75%: 100 danni diventano 175. Non moltiplicare prima per 1,5 e poi per 1,25.''',
13:'''Le Arti danno forma al potere dell’Oculum. La Prima Art è legata ai Titoli del Fato: li ottieni raggiungendo queste soglie con le sue Skill.

• Primo Titolo del Fato: prima Skill della Prima Art al livello 1.
• Secondo Titolo del Fato: seconda Skill della Prima Art al livello 2.
• Terzo Titolo del Fato: terza Skill della Prima Art al livello 3.

Conta la crescita dell’Art, quindi puoi ottenere un Titolo del Fato anche quando il livello del personaggio è ancora basso.''',
14:'''Gli Obser sono pietre o monete con inciso un occhio. Li spendi come valuta, ma possono anche essere un pegno, una ricompensa o un oggetto dal valore rituale, secondo lo scambio che rappresentano.

L’Ascension Dust è una polvere usata nella forgia, nei potenziamenti, nei rituali e nei cerchi magici. Può far ascendere oggetti, armi o poteri.

Nel Diario puoi annotare un ricordo, una promessa, una paura, un sogno o ciò che ti è rimasto di una sessione. Una pagina può dare Ispirazione quando racconta qualcosa che conta per il personaggio.''',
}
pattern=re.compile(r"contentIt: r'''\n(.*?)\n'''",re.S)
counter=0
def chapter(m):
    global counter
    counter+=1
    return "contentIt: r'''\n"+chapters.get(counter,m.group(1))+"\n'''"
active=pattern.sub(chapter,active)
# Rewrite prose around procedural lists while retaining every mechanical entry.
replacements={
'Quando subisci danno, segui questo ordine:':'Risolvi il danno in questo ordine. Le capacità che ignorano Difesa o Scudi saltano soltanto il passaggio indicato dal loro effetto:',
'La Cenere rappresenta consumo fisico, mentale e spirituale.':'La Cenere si accumula quando ti affatichi o trascuri i tuoi bisogni. Segnala in scheda per sapere quando lo sforzo comincia a pesare sui tiri e sulla coscienza.',
'Armi:\n- arma semplice:':'Il bonus dell’arma dipende dal suo tipo:\n- arma semplice:',
'Regola base:\n- ogni dado può crittare':'Guarda prima il risultato naturale del dado, poi applica il modificatore critico:\n- ogni dado può crittare',
'I cerchi magici si attivano con polveri, Materia, Oculum o Varianti.':'Per tracciare un cerchio magico decidi a cosa serve, quale emozione lo sostiene e quale energia sei disposto a cedere. Lo attivi con polveri, Materia, Oculum o Varianti.',
"Open:\n- un'Open si può usare": "Un’Open richiama il potere del personaggio per un effetto più ampio. Tieni conto dei suoi tempi di recupero:\n- un’Open si può usare",
'Titoli:\n- categorie:':'Un Titolo racconta ciò che hai fatto o ciò che ti è accaduto. Per usarlo in scheda, scegli la categoria e compila benefici e limiti:\n- categorie:',
'Azioni stile fight:':'Durante uno scontro in Oculum Dungeon, parti da questi comandi:',
"Questa sezione spiega l'app come se fosse la prima volta che tocchi una scheda.\nL'obiettivo e semplice: capire dove guardare, dove modificare e cosa succede quando tocchi un riquadro.":'Apri la Scheda per leggere le risorse e agire. Usa Modifica rapida per correggere un valore durante la sessione; le pagine dedicate raccolgono invece Titoli, Art, Skill e inventario.',
"Il pannello unificato Combattimento e Centro partita e il cruscotto della scheda.\nServe per le azioni che usi spesso durante una sessione:":'Nel Centro partita trovi le azioni più frequenti:',
'Se non sai dove andare, parti dal Centro partita.':'Puoi tornare al Centro partita dalla pagina Scheda.',
'Questo evita il vecchio problema: i riquadri sembravano solo informativi, ora sono strumenti.':'Il numero mostra la risorsa; il dado accanto esegue il tiro.',
"E il modo migliore per correggere qualcosa durante il gioco.":'Chiudi la modifica per tornare alla scena.',
'Ora cerca anche tratti razziali':'Puoi cercare anche tratti razziali',
'Questa sezione raccoglie le funzioni nuove e come usarle durante una sessione.':'Qui trovi le procedure per dadi, riserve temporanee, Schivata Oculum, oggetti e condivisione. Consulta il paragrafo che riguarda ciò che stai facendo.',
'COMANDI @ NUOVI E DINAMICI':'SCRIVERE UN EFFETTO CON @',
'I nuovi comandi funzionano dentro':'Puoi scrivere questi comandi dentro',
"Per evitare blocchi accidentali, la quantita di dadi viene limitata a un massimo gestibile. I dadi vengono disegnati in modo piu leggero e isolato, cosi il resto della schermata non deve ridisegnarsi inutilmente.":'Il lanciatore pone un limite alla quantità di dadi. Per un tiro di gioco usa il comando della statistica o della capacità interessata.',
'Questo significa che, se subisci danno, viene consumato prima lo Scudo Oculum. Solo quando finisce si passa allo Scudo normale, poi agli HP temporanei, poi agli HP veri.':'Passa alla riserva successiva soltanto quando quella precedente è esaurita.',
'Regola anti-duplicati:\n- il comando non scrive per sempre nella statistica base;\n- se equipaggi un Titolo, il bonus appare;\n- se togli quel Titolo, il bonus sparisce;\n- se lo rimetti, il bonus torna una sola volta;\n- questo evita duplicati di statistiche o rimozioni eccessive.':'Un bonus equipaggiato dura finché tieni attivo ciò che lo concede. Togliendo il Titolo perdi il bonus; rimettendolo lo recuperi una sola volta. La statistica base rimane quella della scheda.',
'Nel minigioco sono stati aggiunti:':'In Oculum Dungeon trovi:',
'Ora include anche:':'Da qui puoi cambiare:',
"PRESTAZIONI\n\nL'app e stata alleggerita per telefono e PC:\n- i pannelli su telefono usano ombre piu leggere;\n- nei pannelli Vita e Scudo Oculum i valori compatti si modificano da dialog, evitando errori di TextField nelle tendine;\n- i dadi sono isolati graficamente per ridurre ridisegni inutili;\n- la barra vita calcola i segmenti una volta sola invece di richiamare piu funzioni ripetute;\n- i set di dadi su telefono sono in tendine chiudibili;\n- i tiri enormi accidentali vengono limitati per non bloccare la UI;\n- il critico brillante viene calcolato in modo semplice: risultato naturale uguale al massimo del dado.":'LEGGERE E MODIFICARE I VALORI\n\nTocca un valore compatto di Vita o Scudo Oculum per aprirne la modifica. Sul telefono puoi richiudere i gruppi di dadi quando hai finito. Il risultato naturale massimo del dado viene evidenziato come critico positivo.',
'Soglie normali e soglie con Rebirth:':'Le soglie indicano il livello necessario per ciascun Grado:',
"Un riferimento completo generato dallo stesso manuale usato dall app. Leggi i capitoli fondamentali in ordine e consulta quelli operativi durante la sessione.":'Per cominciare, leggi le statistiche, i tiri e la crescita. Durante la partita torna ai capitoli su danni, risorse e poteri; la guida alla scheda ti aiuta a trovare i comandi.',
'True strength comes from the eyes.':'Your eye carries traces of what you have lived through.',
'A Title does not grow only because you “spend something”.\nIt grows because the story proves that this power still has something to say.':'The new quest ties this growth to what your character does next.',
'This avoids broken calculations or infinite multiplication chains.':'Apply the combined percentage once to the starting value.',
'This rule is not only technical.\nThe Title must make sense in that moment.':'Choose a moment that fits the meaning of the Title.',
'This section collects the new functions and how to use them during play.':'Use these procedures when rolling dice, managing temporary resources, editing equipment or sharing a sheet.',
}
for old,new in replacements.items(): active=active.replace(old,new)
# Accents in Italian prose only. Preserve literal commands and their aliases.
accents={'Volonta':'Volontà','volonta':'volontà','piu':'più','puo':'può','gia':'già','cosi':'così','finche':'finché','perche':'perché','cio':'ciò','quantita':'quantità','identita':'identità','modalita':'modalità','Modalita':'Modalità','difficolta':'difficoltà','probabilita':'probabilità','priorita':'priorità','Intensita':'Intensità','intensita':'intensità','immunita':'immunità','verra':'verrà','sara':'sarà','Gravita':'Gravità'}
def polish(m):
    text=m.group(1)
    # Keep inline @ expressions byte-for-byte identical.
    chunks=re.split(r'(@[^\s;,:]+)',text)
    for i,chunk in enumerate(chunks):
        if chunk.startswith('@'): continue
        for old,new in accents.items(): chunk=re.sub(r'\b'+old+r'\b',new,chunk)
        for old,new in {'l’app e ':'l’app è ', "l'app e ":"l'app è ", 'massimo e ':'massimo è ', 'risultato e ':'risultato è ', 'probabilità base e ':'probabilità base è ', 'Consumo elevato e ':'Consumo elevato è ', 'mentre e attivo':'mentre è attivo', 'cosa che li contiene e ':'cosa che li contiene è ', 'la frazione e ':'la frazione è ', 'il campo Razza e ':'il campo Razza è ', 'Oculum e una':'Oculum è una', 'Oculum e il':'Oculum è il'}.items(): chunk=chunk.replace(old,new)
        chunk=re.sub(r'(?m)^E (il|la|lo|un|una)\b',r'È \1',chunk)
        chunks[i]=chunk
    return "contentIt: r'''\n"+''.join(chunks)+"\n'''"
active=pattern.sub(polish,active)
active=active.replace("titleIt: '23. Nuove funzioni operative'", "titleIt: '23. Dadi, riserve, oggetti e condivisione'")
active=active.replace("titleEn: '23. New operative functions'", "titleEn: '23. Dice, resources, equipment and sharing'")
# Warm ink, restrained ornaments and a reading layout instead of report styling.
active=active.replace('PdfColors.deepPurple800', 'PdfColor.fromHex(\'#392719\')').replace('PdfColors.deepPurple700', 'PdfColor.fromHex(\'#85602D\')').replace('PdfColors.deepPurple600', 'PdfColor.fromHex(\'#705634\')')
active=active.replace('pw.TextAlign.justify','pw.TextAlign.left')
p.write_text(active+legacy,encoding='utf-8')
