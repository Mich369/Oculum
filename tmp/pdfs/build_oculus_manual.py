from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, KeepTogether
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.pdfmetrics import stringWidth
from pathlib import Path

ROOT = Path(r"C:\Oculum App\oculum")
OUT = ROOT / "output" / "pdf" / "Oculus_Manuale_Libero.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)

for candidate in [
    r"C:\Windows\Fonts\segoeui.ttf",
    r"C:\Windows\Fonts\arial.ttf",
]:
    if Path(candidate).exists():
        pdfmetrics.registerFont(TTFont("Oculus", candidate))
        break
else:
    raise RuntimeError("Font di sistema non trovata")

PAGE_W, PAGE_H = A4
INK = colors.HexColor("#121427")
PARCHMENT = colors.HexColor("#F4F0E4")
AGED_PARCHMENT = colors.HexColor("#E9DFC6")
GOLD = colors.HexColor("#C99B3B")
VIOLET = colors.HexColor("#6D4EB5")
CRIMSON = colors.HexColor("#9F3048")
MIST = colors.HexColor("#E6E0F1")
MUTED = colors.HexColor("#5E6070")
NIGHT = colors.HexColor("#090A14")

GOTHIC = "Oculus"
if Path(r"C:\Windows\Fonts\OLDENGL.TTF").exists():
    pdfmetrics.registerFont(TTFont("Gothic", r"C:\Windows\Fonts\OLDENGL.TTF"))
    GOTHIC = "Gothic"

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="TitleO", fontName=GOTHIC, fontSize=32, leading=38, textColor=GOLD, alignment=TA_CENTER, spaceAfter=12))
styles.add(ParagraphStyle(name="SubTitleO", fontName="Oculus", fontSize=14, leading=19, textColor=VIOLET, alignment=TA_CENTER, spaceAfter=20))
styles.add(ParagraphStyle(name="H1O", fontName="Oculus", fontSize=20, leading=25, textColor=INK, spaceBefore=6, spaceAfter=10))
styles.add(ParagraphStyle(name="H2O", fontName="Oculus", fontSize=13, leading=17, textColor=VIOLET, spaceBefore=8, spaceAfter=5))
styles.add(ParagraphStyle(name="BodyO", fontName="Oculus", fontSize=9.4, leading=13.2, textColor=INK, spaceAfter=6))
styles.add(ParagraphStyle(name="SmallO", fontName="Oculus", fontSize=7.6, leading=10.2, textColor=INK))
styles.add(ParagraphStyle(name="HeaderO", fontName="Oculus", fontSize=7.6, leading=10.2, textColor=colors.white))
styles.add(ParagraphStyle(name="QuoteO", fontName="Oculus", fontSize=10.4, leading=15, textColor=VIOLET, alignment=TA_CENTER, spaceBefore=10, spaceAfter=10))
styles.add(ParagraphStyle(name="CardO", fontName="Oculus", fontSize=8.3, leading=11.2, textColor=INK))
styles.add(ParagraphStyle(name="TinyO", fontName="Oculus", fontSize=6.6, leading=8.5, textColor=INK))

def P(text, style="BodyO"):
    return Paragraph(text, styles[style])

def section(title, intro=None):
    out = [P(title, "H1O")]
    if intro:
        out.append(P(intro))
    return out

def table(rows, widths, header=True, font=7.6):
    converted = []
    for row_index, row in enumerate(rows):
        style = "HeaderO" if header and row_index == 0 else ("SmallO" if font >= 7.5 else "TinyO")
        converted.append([P(str(cell), style) for cell in row])
    t = Table(converted, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    commands = [
        ("GRID", (0,0), (-1,-1), 0.35, colors.HexColor("#C7BED8")),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 5),
        ("RIGHTPADDING", (0,0), (-1,-1), 5),
        ("TOPPADDING", (0,0), (-1,-1), 4),
        ("BOTTOMPADDING", (0,0), (-1,-1), 4),
    ]
    if header:
        commands += [
            ("BACKGROUND", (0,0), (-1,0), INK),
            ("TEXTCOLOR", (0,0), (-1,0), colors.white),
        ]
    if len(rows) > 2:
        for i in range(2, len(rows), 2):
            commands.append(("BACKGROUND", (0,i), (-1,i), colors.HexColor("#FAF8F1")))
    t.setStyle(TableStyle(commands))
    return t

def note(label, text, color=VIOLET):
    t = Table([[P(f"<b>{label}</b><br/>{text}", "CardO")]], colWidths=[17.1*cm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), MIST),
        ("BOX", (0,0), (-1,-1), 0.8, color),
        ("LINEBEFORE", (0,0), (0,-1), 4, color),
        ("LEFTPADDING", (0,0), (-1,-1), 9), ("RIGHTPADDING", (0,0), (-1,-1), 8),
        ("TOPPADDING", (0,0), (-1,-1), 7), ("BOTTOMPADDING", (0,0), (-1,-1), 7),
    ]))
    return t

def footer(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(AGED_PARCHMENT)
    canvas.rect(0, 0, PAGE_W, PAGE_H, stroke=0, fill=1)
    canvas.setStrokeColor(colors.HexColor("#5B3A21"))
    canvas.setLineWidth(1.2)
    canvas.rect(.85*cm, .85*cm, PAGE_W-1.7*cm, PAGE_H-1.7*cm, stroke=1, fill=0)
    canvas.setLineWidth(.3)
    canvas.rect(1.02*cm, 1.02*cm, PAGE_W-2.04*cm, PAGE_H-2.04*cm, stroke=1, fill=0)
    canvas.setStrokeColor(GOLD)
    canvas.setLineWidth(.6)
    canvas.line(1.7*cm, 1.25*cm, PAGE_W-1.7*cm, 1.25*cm)
    canvas.setFont("Oculus", 7)
    canvas.setFillColor(MUTED)
    canvas.drawString(1.7*cm, .8*cm, "OCULUS - Manuale libero, gioco senza app")
    canvas.drawRightString(PAGE_W-1.7*cm, .8*cm, f"{doc.page}")
    canvas.restoreState()

def cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(NIGHT)
    canvas.rect(0, 0, PAGE_W, PAGE_H, stroke=0, fill=1)
    canvas.setStrokeColor(GOLD)
    canvas.setLineWidth(1.4)
    canvas.rect(.85*cm, .85*cm, PAGE_W-1.7*cm, PAGE_H-1.7*cm, stroke=1, fill=0)
    canvas.setLineWidth(.35)
    canvas.rect(1.08*cm, 1.08*cm, PAGE_W-2.16*cm, PAGE_H-2.16*cm, stroke=1, fill=0)
    canvas.setFillColor(colors.HexColor("#252047"))
    canvas.circle(PAGE_W/2, PAGE_H-4.5*cm, 2.55*cm, stroke=0, fill=1)
    canvas.setFillColor(NIGHT)
    canvas.circle(PAGE_W/2+.75*cm, PAGE_H-4.08*cm, 2.3*cm, stroke=0, fill=1)
    canvas.setFillColor(GOLD)
    canvas.setFont("Oculus", 7)
    canvas.drawCentredString(PAGE_W/2, 1.1*cm, "UN GRIMORIO PER STORIE DI FATO, CHAOS E OBLIO")
    canvas.restoreState()

story = []
# Cover
story += [Spacer(1, 4.0*cm), P("OCULUS", "TitleO"), P("Manuale libero di Oculum", "SubTitleO")]
story += [P("Un gioco narrativo cupo, essenziale e trasformabile. Due dadi, poche regole, molte conseguenze.", "QuoteO")]
story += [Spacer(1, .6*cm), note("MANUALE LIBERO", "Non e' necessario usare l'app. Puoi giocare al tavolo, in chat o su un foglio. Master e giocatori possono interpretare come preferiscono Fato, Chaos e Oblio, perfino rinominarli. Le regole sono strumenti: cambiale, tagliale o aggiungine di nuove se la vostra storia migliora.", GOLD), Spacer(1, 1.4*cm)]
story += [P("Livelli 1-12 - Titoli del Fato - Razze - Oculum Art - Monster Book", "SubTitleO"), PageBreak()]

story += section("1. Il cuore del gioco", "Oculus e' una versione semplificata da tavolo: un personaggio affronta un mondo ostile e visionario, nel quale le decisioni sono spinte dal Fato, deviate dal Chaos oppure svuotate dall'Oblio.")
story += [note("COSA SERVE", "Due d20 per giocatore, una scheda, matita e un Master. Se non hai d20, usa un'app dadi o un generatore online. Il Master decide il tono: horror, azione, esplorazione, tragedia o commedia nera.", GOLD), Spacer(1, .3*cm)]
story += [P("<b>La promessa:</b> impari poche procedure e combini poteri semplici. La profondita' non nasce da cinquanta bonus, ma dal posizionamento, dall'elemento scelto, dalle tre Forze e dalle conseguenze narrative.")]
story += [P("<b>La regola d'oro:</b> quando una regola rallenta una scena importante, il Master sceglie una conseguenza chiara e si continua a giocare. L'atmosfera vale piu' della burocrazia.")]
story += section("Le tre Forze")
story += [table([
    ["Forza", "Quando domina", "Effetto sul dado della Forza"],
    ["Fato", "La tua azione segue un presagio, una promessa o il tuo Titolo.", "Risultato 16+: il Master offre un vantaggio, un indizio o una scena favorevole."],
    ["Chaos", "La tua azione rompe il piano, osa l'impossibile o crea disordine.", "Risultato 16+: scegli un effetto extra, ma il Master introduce un costo o una deviazione."],
    ["Oblio", "La tua azione rinuncia, cancella, mente o guarda oltre il limite.", "Risultato 16+: riduci una minaccia o un ricordo; il Master segna una cicatrice."],
], [3*cm, 6.4*cm, 7.7*cm])]
story += [P("All'inizio di una scena il Master indica la Forza attiva. Puo' cambiarla quando le azioni cambiano significato. Non e' un giudizio morale: e' una lente narrativa. Potete rinominarle, per esempio Destino, Fermento e Vuoto.")]

story += section("2. Creare un personaggio")
story += [P("1. Scegli una razza. 2. Scegli un Titolo del Fato. 3. Scegli un elemento. 4. Assegna i dadi iniziali. 5. Descrivi una ferita, un desiderio e una persona che non vuoi perdere. Oculus prende le quattro statistiche da Oculum, ma le trasforma in un sistema nuovo, piu' leggero e completamente indipendente dall'app."),
          table([
              ["Statistica", "Dado iniziale", "A cosa serve"],
              ["Resilienza", "1d4", "Tenuta fisica, mentale e spirituale: sopportare dolore, difendere, restare in piedi."],
              ["Volonta'", "1d4", "Determinazione, pressione offensiva, autocontrollo, intuito e capacita' di imporsi."],
              ["Materia", "1d4", "Corpo, tecnica, struttura, precisione, movimento e capacita' di dare forma alle cose."],
              ["Oculum", "1d4", "Potere magico personale dell'occhio: Arti, percezione dell'ignoto e trasformazione."],
              ["Fato/Chaos/Oblio", "1d4", "Secondo dado di ogni tiro. La sua crescita segue una progressione separata."],
          ], [3.4*cm, 3.2*cm, 10.5*cm]),
          P("Hai inoltre <b>Vita 3 + risultato massimo del dado Resilienza</b>, Difesa 10 e 3 slot Arte. Esempio: Resilienza 1d4 significa 7 Vita; Resilienza 1d10 significa 13 Vita.")]

story += section("3. Fare un tiro")
story += [P("Quando l'esito e' incerto, scegli una statistica e tira <b>il suo dado + il dado della Forza attiva + modificatori</b>. Un bonus non cambia i dadi: si somma dopo il tiro.")]
story += [table([
    ["Esito", "Soglia", "Conseguenza"],
    ["Fallimento vivo", "9 o meno", "Non ottieni cio' che vuoi; il Master muove la minaccia, consuma una risorsa o ti mette davanti a una scelta."],
    ["Successo con prezzo", "10-14", "Ottieni qualcosa, ma scegli un costo oppure il Master ne rivela uno."],
    ["Successo pieno", "15-19", "Ottieni cio' che vuoi come descritto."],
    ["Rivelazione", "20+", "Successo pieno piu' un beneficio della Forza attiva o un dettaglio narrativo favorevole."],
], [3.3*cm, 2.4*cm, 11.4*cm])]
story += [P("<b>Attacchi:</b> tira Materia per colpire in mischia/a distanza, oppure Oculum per un'Arte. Il bersaglio oppone Difesa 10 + protezioni. Danno base: 2; arma pesante o Arte offensiva: 3; 20+ al tiro: +2 danni o un effetto dell'attacco.")]
story += [note("EFFETTI POCHI, CHIARI", "Gli effetti ricorrenti sono solo cinque: <b>Brucia</b> (1 danno a fine turno), <b>Legato</b> (-2 al prossimo movimento), <b>Esposto</b> (+2 al prossimo danno ricevuto), <b>Velato</b> (-2 a chi ti cerca/colpisce), <b>Fratturato</b> (-2 alla prossima azione fisica). Un effetto uguale non si somma: rinnova la durata.")]

story += section("4. Livelli 1-12")
story += [P("Ogni sessione chiusa con una scelta rischiosa, una scoperta o un passo della Quest assegna 1 Progresso. A 3 Progresso sali di livello e torni a 0. Il Master puo' assegnare 2 Progresso per una conclusione eccezionale, mai per il solo combattimento. Il livello massimo e' 12.")]
level_rows = [["Livello", "Dado Forza", "Cosa ottieni"]]
for lvl in range(1, 13):
    force = {1:"1d4", 2:"1d6", 3:"1d6", 4:"1d8", 5:"1d8", 6:"1d10", 7:"1d10", 8:"1d10", 9:"1d10", 10:"1d12", 11:"1d12", 12:"1d20"}[lvl]
    force_step = lvl in (2, 4, 6, 10, 12)
    if lvl == 1:
        reward = "Scegli due Arti base e 1 tratto razziale."
    else:
        points = 6 if force_step else 9
        reward = f"Aumenta di una faccia un dado statistica (max 1d20) e distribuisci {points} punti bonus come + ai tiri."
        if force_step:
            reward += " Il dado delle tre Forze aumenta."
    if lvl == 12: reward += " Completi il Titolo: scegli un epilogo e un potere di leggenda."
    level_rows.append([str(lvl), force, reward])
story += [table(level_rows, [1.7*cm, 2.5*cm, 12.9*cm])]
story += [P("<b>Punti bonus:</b> assegna i punti tra Resilienza, Volonta', Materia e Oculum. Ogni punto e' un +1 ai tiri. Massimo +4 alla stessa statistica nello stesso livello. Ai livelli 2, 4, 6, 10 e 12, quando cresce il dado delle tre Forze, ricevi 6 punti; negli altri level up ricevi 9 punti.")]

story += [PageBreak()] + section("5. Titoli del Fato e le dodici Missioni", "Scegli un Titolo al livello 1. Ogni Titolo ha 12 Missioni assegnate dal Master: non sono prestabilite nel manuale, perche' devono parlare della vostra storia. Completa una Missione per sbloccare la seguente. Le Skill non si acquistano con punti: il Master le sblocca come ricompensa o rivelazione di una Missione del Titolo.")
titles = {
"La Corona Senza Testa": ("Buff: Resilienza aumenta di un grado di dado (max 1d20).", "Punto cieco: -2 ai tiri per chiedere aiuto o ammettere una sconfitta."),
"Il Cartografo del Vuoto": ("Buff: una volta per scena, dopo aver esplorato, ritira il dado Materia o Oculum.", "Punto cieco: -2 ai tiri quando segui un piano altrui senza poterlo modificare."),
"La Culla di Cenere": ("Buff: la prima volta per scena che un alleato va a 0 Vita, recupera 2 Vita e puoi agire subito.", "Punto cieco: -2 ai tiri per abbandonare qualcuno o qualcosa al fuoco."),
"Il Divoratore di Promesse": ("Buff: +2 Volonta' quando mantieni un patto che ti costa qualcosa; una volta per sessione trasforma un 10-14 in 15.", "Punto cieco: -2 ai tiri contro chi ha mantenuto una promessa con te."),
"La Figlia del Temporale": ("Buff: Materia aumenta di un grado di dado (max 1d20) e ignori il primo ostacolo di movimento per scena.", "Punto cieco: -2 ai tiri quando resti immobile, aspetti o proteggi una posizione."),
"L'Ultimo Occhio": ("Buff: Oculum aumenta di un grado di dado (max 1d20); una volta per scena chiedi al Master quale presenza e' nascosta.", "Punto cieco: -2 ai tiri per ignorare una verita' che hai gia' visto."),
}
for title, (buff, blind_spot) in titles.items():
    story += [P(title, "H2O")]
    story += [P(f"<b>{buff}</b><br/><b>{blind_spot}</b>", "SmallO")]
    cells=[]
    for i in range(1, 13): cells.append(P(f"<b>Missione {i}:</b> assegnata dal Master", "TinyO"))
    grid=[cells[:4],cells[4:8],cells[8:12]]
    t=Table(grid,colWidths=[4.28*cm]*4)
    t.setStyle(TableStyle([("GRID",(0,0),(-1,-1),.35,colors.HexColor("#C7BED8")),("BACKGROUND",(0,0),(-1,-1),colors.HexColor("#FAF8F1")),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),4),("RIGHTPADDING",(0,0),(-1,-1),4),("TOPPADDING",(0,0),(-1,-1),4),("BOTTOMPADDING",(0,0),(-1,-1),4)]))
    story += [t, Spacer(1, .18*cm)]

story += [PageBreak()] + section("6. Razze e tratti razziali", "Ogni razza ha tre buff. Scegline uno al livello 1 e gli altri al livello 4 e 8. Una campagna libera puo' permettere ibridi: prendi due razze e scegli due buff totali.")
races = [
("Ratfolk", "Sopravvissuti di fogne, tunnel e citta' divorate.", ["Branco: +1 Volonta' se attacchi con almeno un alleato contro lo stesso bersaglio.", "Denti di Rame: una volta per scena, dopo un 9 o meno in Materia, ritira il dado statistica.", "Fuga Impossibile: aumenta Materia di un grado di dado (max 1d20) quando inseguito."]),
("Nati di Vetro", "Corpi traslucidi, memorie taglienti.", ["Rifrazione: una volta per scena diventi Velato fino al tuo prossimo turno.", "Scheggia Sincera: +2 Volonta' per smascherare una bugia.", "Risonanza: aumenta Volonta' di un grado di dado quando ascolti un'eco, un oggetto o una rovina."]),
("Ferrum", "Umani forgiati con ossa metalliche e cuori incandescenti.", ["Corazza Viva: Difesa +1 se non indossi armatura pesante.", "Magnete: richiama o respingi un piccolo oggetto metallico vicino.", "Incudine: aumenta Resilienza di un grado di dado quando subisci danno per proteggere un altro."]),
("Marea", "Anfibi nati tra sorgenti nere e mari senza luna.", ["Pelle di Marea: ignori il primo effetto Brucia per scena.", "Senso di Profondita': +2 Oculum per percepire presenze in acqua, nebbia o pioggia.", "Flusso: aumenta Oculum di un grado di dado se inizi la scena bagnato o sott'acqua."]),
("Cervidi del Crepuscolo", "Figli di foreste che ricordano i nomi dei morti.", ["Palchi di Bruma: puoi creare una breve copertura di rami e nebbia.", "Passo Silenzioso: +2 Materia per attraversare natura ostile senza lasciare tracce.", "Istinto Antico: aumenta Volonta' di un grado di dado quando difendi il tuo branco o territorio."]),
("Seleniti", "Pelle pallida e occhi che riflettono sogni altrui.", ["Sogno Condiviso: una volta per riposo, chiedi al Master un'immagine vera sul prossimo pericolo.", "Luce Fredda: +1 a tutti i tiri contro creature d'ombra.", "Orbita: aumenta Oculum di un grado di dado durante la notte o sotto cielo aperto."]),
("Ceneriti", "Nati dalla cenere di un incendio che non fini' mai.", ["Ultima Brace: quando scendi a 0 Vita, resta a 1 Vita una volta per sessione.", "Fuliggine: lasci una traccia che solo tu e gli alleati potete leggere.", "Ritorno Caldo: aumenta Resilienza di un grado di dado dopo che un alleato cade a 0 Vita."]),
("Vesperi", "Esuli alati, con ombre che arrivano in ritardo.", ["Ali Residue: ignori un ostacolo verticale basso per scena.", "Ombra Ritardata: dopo un successo pieno puoi diventare Velato fino a muoverti.", "Picchiata: aumenta Materia di un grado di dado quando attacchi dall'alto o da una posizione vantaggiosa."]),
("Umani delle Citta' Murate", "Tenaci, ambiziosi e capaci di costruire ordine nel terrore.", ["Adattamento: dopo un fallimento vivo, +1 al prossimo tiro con la stessa statistica.", "Volto Comune: una volta per scena ottieni accesso a un luogo civile o una folla senza destare sospetto.", "Secondo Fiato: aumenta Resilienza di un grado di dado quando difendi un rifugio, una casa o una comunita'."]),
("Umani delle Frontiere", "Carovanieri, cacciatori e superstiti di territori mai davvero domati.", ["Occhio del Sentiero: +2 Materia per trovare una via, una preda o acqua sicura.", "Mani Pronte: estrai, ripari o prepari un oggetto comune senza spendere un'azione.", "Nervi d'Acciaio: aumenta Volonta' di un grado di dado quando sei isolato dal gruppo."]),
("Umani delle Torri", "Archivisti, tecnici e nobili decaduti che cercano ancora una legge nel caos.", ["Formazione: una volta per scena aggiungi +2 a un tiro di Materia o Volonta' dopo averlo visto fallire.", "Nome Giusto: puoi dichiarare di conoscere un dettaglio utile su una fazione; il Master aggiunge un costo.", "Studio Ostinato: aumenta Oculum di un grado di dado quando usi un oggetto antico o una formula scoperta."]),
("Notturni", "Umani toccati da una notte senza alba, ma ancora fedeli ai propri nomi.", ["Visione Bassa: +2 Oculum al buio, nella nebbia o sottoterra.", "Sangue Freddo: ignori il primo tentativo di spaventarti per scena.", "Luna Interna: aumenta Volonta' di un grado di dado quando resisti a controllo, corruzione o follia."]),
("Golem di Creta", "Corpi modellati con argilla sacra e un desiderio lasciato a meta'.", ["Peso Gentile: non puoi essere spinto da creature di taglia umana.", "Mani di Fango: crei un piccolo attrezzo o una chiave rozza una volta per scena.", "Forma Ricordata: aumenta Resilienza di un grado di dado quando ripari una rovina o difendi un passaggio."]),
("Sirene del Fango", "Voci splendide in paludi nere, con occhi che non smettono di piangere.", ["Canto di Torba: +2 Volonta' per calmare, convincere o distrarre una creatura cosciente.", "Scivolare: attraversi fango, acqua bassa e strettoie senza rallentare.", "Ritornello: aumenta Oculum di un grado di dado quando un alleato segue volontariamente la tua indicazione."]),
("Ossidiani", "Figli di vulcani spenti, taglienti anche quando sorridono.", ["Pelle Nera: il primo danno fisico ricevuto per scena e' ridotto di 1.", "Taglio Riflesso: dopo che un nemico ti manca, puoi infliggere 1 danno se e' vicino.", "Vetro Vulcanico: aumenta Materia di un grado di dado quando rompi una difesa, una serratura o un'armatura."]),
("Ninfee Pallide", "Persone nate dai laghi funerari, con radici sottili nel cuore.", ["Radici Quietanti: una volta per scena rimuovi Fratturato da un alleato vicino.", "Sussurro d'Acqua: percepisci se un luogo e' stato segnato da morte recente.", "Fioritura Funebre: aumenta Oculum di un grado di dado vicino a tombe, rovine o spiriti inquieti."]),
]
for name, desc, buffs in races:
    story += [P(name, "H2O"), P(desc, "SmallO")]
    story += [table([["1", "2", "3"], buffs], [5.7*cm]*3)]

story += section("7. Oculum Art", "Scegli un elemento. Al livello 1 conosci due Arti base. Le nuove Skill e Arti non si comprano: si sbloccano soltanto completando una Missione del Titolo assegnata dal Master. Ogni Arte costa 1 Focalizzazione: hai 3 Focalizzazione per scena e la recuperi con un minuto di quiete, un riposo o una conseguenza narrativa accettata.")
story += [note("COMBINAZIONI SENZA PESO", "Un'Arte puo' applicare un solo effetto. Se un alleato colpisce un bersaglio con un effetto compatibile, puo' trasformarlo: Brucia + Aria diventa fiammata (+1 danno), Legato + Terra diventa prigione (non si muove un turno), Velato + Ombra diventa sparizione (non puo' essere bersagliato da lontano fino al turno successivo). Il Master puo' inventare altre combinazioni mantenendo un solo effetto attivo.", GOLD)]
arts = {
"Fuoco": [("Filo di Brace", "3 danni a un bersaglio vicino."),("Fiamma Errante", "Muovi una fiamma tra tre zone; illumina e rivela il nascosto."),("Marchio di Cenere", "Nessun danno: il bersaglio e' Esposto."),("Cuore di Fornace", "Assorbi Brucia da un alleato e recuperi 1 Vita."),("Pugnale Solare", "2 danni; se eri Velato, +2 al tiro."),("Coro delle Scintille", "Tre alleati ottengono +1 al prossimo tiro offensivo.")],
"Acqua": [("Ago di Marea", "2 danni e Legato se il bersaglio e' vicino a liquidi."),("Velo di Pioggia", "Crea Velato per te o un alleato fino al prossimo turno."),("Memoria Sommersa", "Leggi l'ultima emozione forte impressa in un luogo."),("Morsa di Sale", "3 danni contro una creatura gia' Fratturata."),("Passo di Goccia", "Attraversa una linea di pericolo senza provocare reazioni."),("Pozzo Inverso", "Sposta una creatura piccola in una zona adiacente.")],
"Terra": [("Chiodo di Basalto", "2 danni e Legato."),("Muro di Argilla", "Crea copertura per due persone fino a fine scena."),("Polvere d'Osso", "Rivela impronte, sangue o passaggi invisibili."),("Pugno di Faglia", "3 danni, ma resti fermo fino al prossimo turno."),("Tomba Gentile", "Un alleato a 0 Vita non muore finche' la scena non cambia."),("Radice del Giuramento", "Un bersaglio Esposto diventa Fratturato.")],
"Aria": [("Lama di Pressione", "2 danni a distanza."),("Soffio di Sgomento", "Spingi un nemico in una zona adiacente."),("Voce Tra le Crepe", "Invia una frase breve a un alleato che conosci."),("Cerchio di Vento", "Devia il prossimo attacco a distanza contro un alleato."),("Polline di Nebbia", "Rendi Velata una piccola area."),("Caduta Senza Fine", "Un nemico Legato subisce 3 danni e perde la reazione.")],
"Luce": [("Sigillo d'Aurora", "Un alleato recupera 2 Vita."),("Lancia di Specchio", "2 danni; ignora Velato."),("Giudizio Cieco", "Un nemico Esposto non puo' nascondersi fino a fine scena."),("Lanterna del Nome", "Chiedi il vero nome o la debolezza simbolica di una creatura."),("Pelle di Alba", "Rimuovi Fratturato o Brucia da un alleato."),("Fenditura Bianca", "3 danni a un'ombra, un'illusione o una creatura corrotta.")],
"Ombra": [("Ago di Notte", "2 danni; se il bersaglio e' solo, +1 danno."),("Porta Nera", "Scambia posizione con un alleato visibile."),("Sussurro Parassita", "Un bersaglio riceve -2 alla prossima Volonta'."),("Mantello Senza Volto", "Diventi Velato e non lasci tracce per una scena."),("Morsa dell'Assente", "Un nemico Velato diventa Esposto."),("Sonno della Statua", "Un bersaglio Fratturato non usa reazioni fino al suo turno.")],
}
for element, spells in arts.items():
    story += [P(element, "H2O"), table([["Arte", "Effetto"]] + [[a,e] for a,e in spells], [5.2*cm, 12*cm])]

story += [PageBreak()] + section("8. Mostri del Monster Book", "Creature originali per un mondo cupo, grottesco e delirante. Molte pensano, parlano e soffrono. Non sono semplici bersagli: ciascuna vuole qualcosa.")
monsters = [
("Mendicante delle Palpebre", "1", "Un ammasso di occhi cuciti in una veste umida. Chiede di essere guardato.", "Quando qualcuno lo fissa, infligge Velato a se stesso e sussurra un segreto vero."),
("Cane delle Scale", "1", "Cane troppo lungo con zampe umane. Abita gradini che non finiscono.", "Se viene ferito, la scala cambia direzione e separa il gruppo."),
("Suora di Catrame", "2", "Una figura rituale che raccoglie nomi in coppe nere.", "Offre protezione in cambio del nome di chi ami."),
("Principe dei Nidi", "3", "Bambino coronato da becchi, lucido e imperioso.", "Comanda stormi di ossa; vuole essere riconosciuto come re."),
("Archivista Senza Bocca", "3", "Bibliotecario con libri al posto dei denti.", "Conosce un fatto utile ma chiede una memoria come pagamento."),
("Madre di Ruggine", "4", "Gigante metallica gravida di armi rotte.", "Ogni arma che la colpisce puo' arrugginire; piange per ogni spada."),
("Volto che Cammina", "4", "Un volto enorme che usa ombre come gambe.", "Non attacca finche' qualcuno non mente; allora ripete la menzogna come maledizione."),
("Carnefice delle Campane", "5", "Corpo senza testa, campana al posto del torace.", "Ogni rintocco applica Fratturato a chi ha tradito un patto."),
("Fratelli del Pozzo", "5", "Tre corpi condividono una sola coscienza, litigano con se stessi.", "Puoi convincere un fratello a sabotare gli altri due."),
("Vasca di Seta", "6", "Massa gelatinosa che genera versioni infantili dei caduti.", "Propone di restituire un morto, ma in forma incompleta."),
("Cavaliere del Sonno Rosso", "6", "Armatura vuota abitata da una febbre che parla.", "Ogni sua ferita crea un sogno comune, utile ma instabile."),
("Oracolo Inverso", "7", "Profeta appeso al soffitto, occhi nelle mani.", "Predice con certezza la scelta che non farai."),
("Balena dei Corridoi", "7", "Creatura enorme che nuota dentro architetture abbandonate.", "Puoi entrare nel suo ventre per attraversare una citta'."),
("Il Compagno di Tutti", "8", "Copia affettuosa di un alleato, sempre un passo fuori tempo.", "Non mente mai, ma dice verita' nel momento peggiore."),
("Santo del Nervosismo", "8", "Santo vivo composto da mani tremanti.", "Aumenta il panico e concede poteri a chi accetta di non dormire."),
("Eiva Minore", "9", "Ex umano che ha superato il limite della coscienza e ora sente le emozioni come colori commestibili.", "Parla con lucidita' crudele. Non vuole uccidere: vuole riscrivere cio' che provi."),
("Regina delle Dodici Lingue", "10", "Eiva che pensa in dodici voci contemporanee e conserva citta' nei polmoni.", "Ogni patto con lei cambia una regola del luogo."),
("Eiva Baghest", "12", "Sovrana oltre l'umano. Non e' un boss obbligatorio: e' una presenza che trasforma il desiderio in obbedienza.", "Puoi sconfiggerla solo decidendo cosa nessuno deve piu' desiderare."),
]
story += [table([["Mostro", "Lvl", "Aspetto e desiderio", "Segno di scena"]] + [list(m) for m in monsters], [3.4*cm,1*cm,7*cm,5.7*cm], font=6.6)]

story += [PageBreak()] + section("9. Regole opzionali: follia e corruzione", "Usale soltanto se il gruppo desidera horror psicologico. Prima di iniziare, concordate limiti e temi da evitare.")
story += [P("<b>Follia.</b> Segna 1 Follia quando affronti un orrore incomprensibile, tradisci una convinzione fondamentale o fallisci un tiro di Oblio con 9 o meno. A 3 Follia, il Master presenta un <b>Mostro d'Ombra</b>: solo tu lo vedi, ti attacca e non puoi colpirlo. Puoi liberartene con un gesto di fiducia, una confessione, un riposo sicuro o un tiro di Volonta' 15+. A 6 Follia scegli: perdi una memoria importante, lasci il personaggio al Master per una scena, oppure trasformi il Mostro d'Ombra in un presagio utile e azzeri la Follia.")]
story += [P("<b>Corruzione Rossa.</b> Segna Corruzione quando usi potere per umiliare, dominare o ferire oltre il necessario. Ogni punto intensifica un'emozione negativa scelta: rabbia, gelosia, paura, disprezzo. A 3 punti il Master puo' imporre un impulso; a 6 punti diventi un suddito di <b>Eiva Baghest</b> finche' non compi un atto di rinuncia autentica o non ricevi aiuto dal gruppo.")]
story += [P("<b>Corruzione Viola.</b> Segna Corruzione quando accetti un ordine soprannaturale in cambio di potere o verita'. A 3 punti il tuo padrone puo' darti un comando semplice; a 6 devi eseguirne le parole, restando cosciente e ricordando tutto. Il gruppo puo' spezzare il vincolo trovando il nome del padrone, contrattando un prezzo piu' alto o trasformando l'ordine in una contraddizione.")]
story += [note("EIVA", "Gli Eiva sono mostri dal livello 9 in su che hanno raggiunto la coscienza umana e l'hanno superata. Non sono automaticamente malvagi: sono troppo vasti, troppo lucidi e spesso incapaci di rispettare una vita come qualcosa di separato.", CRIMSON)]

story += section("10. Master: preparazione rapida")
story += [table([
    ["Prima della sessione", "Durante", "Dopo"],
    ["Scegli una domanda: Chi mente? Cosa manca? Che cosa vuole il mostro? Prepara 3 luoghi e 1 presagio.", "Attiva una Forza. Chiedi sempre: cosa rischi? cosa vuoi salvare? Su 9 o meno, muovi il mondo, non bloccare il gioco.", "Assegna Progresso se e' cambiato qualcosa. Sblocca la Quest successiva se la precedente e' stata affrontata davvero."],
], [5.7*cm]*3)]
story += [P("Ispirazioni di tono: combattimenti leggibili e scelte tattiche; poteri con condizioni nette e identita' personale; alchimia e trasformazione con prezzi materiali o morali. Le Arti di questo manuale sono originali: usa quelle suggestioni come direzione di ritmo, mai come regole da copiare.")]
story += [P("<b>Bilanciamento semplice:</b> una minaccia di livello pari al gruppo richiede 2-3 successi pieni per essere risolta; una minaccia di livello superiore richiede un vantaggio narrativo, una debolezza trovata o un patto. Non aumentare solo i punti Vita: cambia obiettivi, ambiente e desideri del nemico.")]

story += [PageBreak()] + section("11. Scheda rapida")
story += [P("Copia questa pagina su un foglio. Puoi sostituire qualsiasi voce con parole della vostra ambientazione.")]
sheet_rows = [
    ["Nome", "", "Razza", "", "Titolo del Fato", ""],
    ["Ferita", "", "Desiderio", "", "Persona da proteggere", ""],
    ["Livello", "1", "Progresso", "0/3", "Focalizzazione", "3/3"],
    ["Resilienza", "1d4 + ___", "Volonta'", "1d4 + ___", "Materia", "1d4 + ___"],
    ["Oculum", "1d4 + ___", "Forza", "1d4 + ___", "Vita", "3 + dado Res."],
    ["Elemento", "", "Arte 1", "", "Arte 2", ""],
    ["Tratto razziale 1", "", "Tratto razziale 2", "", "Tratto razziale 3", ""],
    ["Quest attiva", "", "Follia", "0/6", "Corruzione Rossa/Viola", "0/6"],
]
story += [table(sheet_rows, [2.8*cm,3.0*cm,2.8*cm,3.0*cm,3.0*cm,2.5*cm], header=False)]
story += [Spacer(1,.4*cm), note("PROMEMORIA", "Tiro = dado Statistica + dado della Forza attiva + bonus. 9 o meno: fallimento vivo. 10-14: successo con prezzo. 15-19: successo pieno. 20+: rivelazione. Forza: d4 (lvl 1), d6 (2), d8 (4), d10 (6), d12 (10), d20 (12). A ogni level up: +1 faccia a un dado statistica fino a d20 e 6 punti quando cresce la Forza, altrimenti 9.", GOLD)]
story += [Spacer(1,.7*cm), P("Fine del manuale - ma non della storia.", "QuoteO")]

doc = SimpleDocTemplate(str(OUT), pagesize=A4, rightMargin=1.7*cm, leftMargin=1.7*cm, topMargin=1.55*cm, bottomMargin=1.7*cm, title="Oculus - Manuale libero")
doc.build(story, onFirstPage=cover, onLaterPages=footer)
print(OUT)
