from __future__ import annotations

import argparse
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


INK = colors.HexColor("#172238")
BLUE = colors.HexColor("#286B8D")
CYAN = colors.HexColor("#35A7B7")
GOLD = colors.HexColor("#D8A642")
PALE = colors.HexColor("#EDF5F7")
PARCHMENT = colors.HexColor("#FAF7EF")
MUTED = colors.HexColor("#536273")
RED = colors.HexColor("#9A3E43")
GREEN = colors.HexColor("#367C62")
WHITE = colors.white


def register_fonts() -> tuple[str, str]:
    windows_fonts = Path("C:/Windows/Fonts")
    regular = windows_fonts / "arial.ttf"
    bold = windows_fonts / "arialbd.ttf"
    if regular.exists() and bold.exists():
        pdfmetrics.registerFont(TTFont("OculumSans", str(regular)))
        pdfmetrics.registerFont(TTFont("OculumSansBold", str(bold)))
        return "OculumSans", "OculumSansBold"
    return "Helvetica", "Helvetica-Bold"


FONT, FONT_BOLD = register_fonts()


def page_decoration(canvas, doc) -> None:
    width, height = A4
    page = canvas.getPageNumber()
    canvas.saveState()
    if page == 1:
        canvas.setFillColor(INK)
        canvas.rect(0, 0, width, height, fill=1, stroke=0)
        canvas.setFillColor(CYAN)
        canvas.circle(width - 34 * mm, height - 35 * mm, 22 * mm, fill=0, stroke=1)
        canvas.setStrokeColor(GOLD)
        canvas.setLineWidth(2)
        canvas.circle(width - 34 * mm, height - 35 * mm, 12 * mm, fill=0, stroke=1)
    else:
        canvas.setFillColor(PARCHMENT)
        canvas.rect(0, 0, width, height, fill=1, stroke=0)
        canvas.setFillColor(INK)
        canvas.rect(0, height - 17 * mm, width, 17 * mm, fill=1, stroke=0)
        canvas.setFillColor(CYAN)
        canvas.rect(0, height - 18.5 * mm, width, 1.5 * mm, fill=1, stroke=0)
        canvas.setFont(FONT_BOLD, 8)
        canvas.setFillColor(WHITE)
        canvas.drawString(15 * mm, height - 11 * mm, "OCULUM MANUALE LITE")
        canvas.setFont(FONT, 8)
        canvas.setFillColor(MUTED)
        canvas.drawString(15 * mm, 10 * mm, "Versione fiction-first 2d6 - senza app")
        canvas.drawRightString(width - 15 * mm, 10 * mm, str(page - 1))
    canvas.restoreState()


styles = getSampleStyleSheet()
TITLE = ParagraphStyle(
    "Title",
    fontName=FONT_BOLD,
    fontSize=31,
    leading=34,
    textColor=WHITE,
    alignment=TA_LEFT,
    spaceAfter=9,
)
SUBTITLE = ParagraphStyle(
    "Subtitle",
    fontName=FONT,
    fontSize=14,
    leading=19,
    textColor=colors.HexColor("#D9EEF1"),
    alignment=TA_LEFT,
)
CHAPTER = ParagraphStyle(
    "Chapter",
    fontName=FONT_BOLD,
    fontSize=22,
    leading=25,
    textColor=INK,
    spaceAfter=8,
)
KICKER = ParagraphStyle(
    "Kicker",
    fontName=FONT_BOLD,
    fontSize=8.5,
    leading=10,
    textColor=CYAN,
    spaceAfter=4,
)
H2 = ParagraphStyle(
    "H2",
    fontName=FONT_BOLD,
    fontSize=13.5,
    leading=16,
    textColor=BLUE,
    spaceBefore=7,
    spaceAfter=4,
)
BODY = ParagraphStyle(
    "Body",
    fontName=FONT,
    fontSize=9.3,
    leading=12.2,
    textColor=INK,
    spaceAfter=5,
)
SMALL = ParagraphStyle(
    "Small",
    fontName=FONT,
    fontSize=8.1,
    leading=10.5,
    textColor=INK,
)
NOTE = ParagraphStyle(
    "Note",
    fontName=FONT,
    fontSize=8.7,
    leading=11.4,
    textColor=MUTED,
    leftIndent=8,
    rightIndent=8,
    spaceBefore=4,
    spaceAfter=6,
)
MOVE_TITLE = ParagraphStyle(
    "MoveTitle",
    fontName=FONT_BOLD,
    fontSize=11.5,
    leading=14,
    textColor=WHITE,
)
TABLE_HEAD = ParagraphStyle(
    "TableHead",
    fontName=FONT_BOLD,
    fontSize=8.2,
    leading=10,
    textColor=WHITE,
    alignment=TA_LEFT,
)
TABLE_TEXT = ParagraphStyle(
    "TableText",
    fontName=FONT,
    fontSize=7.8,
    leading=9.8,
    textColor=INK,
)
SHEET_LABEL = ParagraphStyle(
    "SheetLabel",
    fontName=FONT_BOLD,
    fontSize=8,
    leading=9.5,
    textColor=BLUE,
)


def P(text: str, style=BODY) -> Paragraph:
    return Paragraph(text, style)


def bullets(items: list[str]) -> list[Paragraph]:
    return [P(f"<b>-</b> {item}", BODY) for item in items]


def chapter(story: list, number: str, title: str, subtitle: str) -> None:
    story.append(PageBreak())
    story.append(P(number.upper(), KICKER))
    story.append(P(title, CHAPTER))
    story.append(P(subtitle, NOTE))


def info_box(title: str, text: str, color=BLUE) -> Table:
    data = [
        [P(title, MOVE_TITLE)],
        [P(text, SMALL)],
    ]
    table = Table(data, colWidths=[172 * mm], hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), color),
                ("BACKGROUND", (0, 1), (-1, -1), PALE),
                ("BOX", (0, 0), (-1, -1), 0.8, color),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def move_box(name: str, trigger: str, success: str, mixed: str, miss: str) -> Table:
    data = [
        [P(name, MOVE_TITLE), ""],
        [P(f"<b>Quando:</b> {trigger}", SMALL), ""],
        [P("<b>10+</b>", TABLE_TEXT), P(success, TABLE_TEXT)],
        [P("<b>7-9</b>", TABLE_TEXT), P(mixed, TABLE_TEXT)],
        [P("<b>6-</b>", TABLE_TEXT), P(miss, TABLE_TEXT)],
    ]
    table = Table(data, colWidths=[20 * mm, 152 * mm], hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("SPAN", (0, 0), (1, 0)),
                ("SPAN", (0, 1), (1, 1)),
                ("BACKGROUND", (0, 0), (1, 0), BLUE),
                ("BACKGROUND", (0, 1), (1, 1), PALE),
                ("BACKGROUND", (0, 2), (0, 2), GREEN),
                ("BACKGROUND", (0, 3), (0, 3), GOLD),
                ("BACKGROUND", (0, 4), (0, 4), RED),
                ("TEXTCOLOR", (0, 2), (0, 4), WHITE),
                ("BOX", (0, 0), (-1, -1), 0.7, BLUE),
                ("INNERGRID", (0, 2), (-1, -1), 0.3, colors.HexColor("#B8C8D0")),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]
        )
    )
    return table


def data_table(headers: list[str], rows: list[list[str]], widths: list[float]) -> Table:
    data = [[P(value, TABLE_HEAD) for value in headers]]
    data.extend([[P(value, TABLE_TEXT) for value in row] for row in rows])
    table = Table(data, colWidths=[value * mm for value in widths], repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), INK),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [WHITE, PALE]),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#AEBCC4")),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]
        )
    )
    return table


def build_story() -> list:
    story: list = []

    story.extend(
        [
            Spacer(1, 78 * mm),
            P("OCULUM", TITLE),
            P("MANUALE LITE", TITLE),
            Spacer(1, 4 * mm),
            P("Avventure fiction-first con 2d6", SUBTITLE),
            P("Regole complete per giocare senza app e senza calcoli complessi", SUBTITLE),
            Spacer(1, 17 * mm),
            info_box(
                "COSA SERVE",
                "Due dadi a sei facce, carta, matita e alcuni segnalini. Una persona fa da Master; gli altri interpretano gli avventurieri.",
                CYAN,
            ),
            Spacer(1, 7 * mm),
            P(
                "Versione autonoma ispirata al ritmo delle normali partite fiction-first: descrivi, attiva una mossa, tira 2d6 e lascia che la storia cambi.",
                SUBTITLE,
            ),
        ]
    )

    chapter(story, "01", "Partire in dieci minuti", "Il gruppo crea personaggi e dungeon senza preparare formule.")
    story.append(P("Il patto del tavolo", H2))
    story.extend(
        bullets(
            [
                "Descrivi prima ciò che fai. Una mossa si attiva soltanto quando la storia la rende necessaria.",
                "Se non esiste rischio, non tirare: l'azione riesce oppure il Master mostra cosa serve.",
                "Il Master non tira dadi. Reagisce ai risultati e rende concrete le conseguenze.",
                "Fai domande, usa le risposte e lascia spazio a tutti.",
            ]
        )
    )
    story.append(P("Crea il personaggio", H2))
    story.append(
        data_table(
            ["Passo", "Scelta"],
            [
                ["1", "Scrivi nome, aspetto, origine e una cosa che vuoi ottenere."],
                ["2", "Scegli un Ruolo: Guardiano, Esploratore, Mistico o Vincolatore."],
                ["3", "Assegna +2, +1, +1 e +0 a Resilienza, Volontà, Materia e Oculum."],
                ["4", "Segna HP, dado danno, Armatura e Oculum indicati dal Ruolo."],
                ["5", "Scegli due legami con gli altri personaggi e una dotazione."],
            ],
            [19, 153],
        )
    )
    story.append(P("Le quattro statistiche", H2))
    story.append(
        data_table(
            ["Stat", "Si usa quando..."],
            [
                ["Resilienza", "resisti, sopporti, proteggi o resti in piedi"],
                ["Volontà", "combatti, imponi la tua presenza o superi la paura"],
                ["Materia", "agisci con precisione, rapidità, tecnica o furtività"],
                ["Oculum", "usi Arti, rune, visioni o poteri sovrannaturali"],
            ],
            [32, 140],
        )
    )

    chapter(story, "02", "La regola centrale", "Ogni tiro usa la stessa lettura. Non esistono DT o somme nascoste.")
    story.append(info_box("TIRA 2D6 + STAT", "10+ successo pieno. 7-9 successo con costo, scelta o pericolo. 6- il Master fa una mossa e tu segni 1 EXP.", GOLD))
    story.append(P("Come si risolve", H2))
    story.extend(
        bullets(
            [
                "Il giocatore dice cosa vuole ottenere e come agisce.",
                "Il gruppo riconosce la mossa e la statistica coerente.",
                "Si tirano 2d6, si aggiunge una sola statistica e si legge l'esito.",
                "Dopo il tiro la fiction cambia: non ripetere lo stesso tentativo senza cambiare approccio o situazione.",
            ]
        )
    )
    story.append(P("Vantaggio e svantaggio", H2))
    story.append(P("Se una posizione è nettamente favorevole tira 3d6 e tieni i due migliori. Se è nettamente sfavorevole tira 3d6 e tieni i due peggiori. Non cumulare più vantaggi o svantaggi."))
    story.append(P("Aiuto del Master", H2))
    story.append(
        data_table(
            ["Esito", "Il Master fa..."],
            [
                ["10+", "Conferma il successo e mostra la nuova opportunità."],
                ["7-9", "Offre una scelta difficile, un prezzo, un effetto ridotto o un pericolo in arrivo."],
                ["6-", "Rivela una minaccia, infligge danno, separa, consuma risorse o cambia la situazione."],
            ],
            [25, 147],
        )
    )

    chapter(story, "03", "Mosse di azione", "Queste mosse coprono la maggior parte di una sessione.")
    story.extend(
        [
            move_box(
                "SFIDARE IL PERICOLO",
                "agisci nonostante una minaccia immediata, tira con la statistica coerente.",
                "Superi il pericolo e ottieni ciò che cercavi.",
                "Riesci, ma scegli: perdi tempo, consumi qualcosa, subisci un effetto ridotto oppure finisci in una posizione difficile.",
                "Il pericolo si realizza e segni 1 EXP.",
            ),
            Spacer(1, 6),
            move_box(
                "PERCEPIRE LA VERITÀ",
                "osservi attentamente un luogo, una creatura o una situazione, tira +Materia.",
                "Fai tre domande utili e ottieni risposte sincere.",
                "Fai una domanda utile; la risposta è sincera ma può rivelare un nuovo rischio.",
                "Il Master mostra qualcosa di vero nel modo peggiore e segni 1 EXP.",
            ),
            Spacer(1, 6),
            move_box(
                "PARLARE CON LEVA",
                "chiedi qualcosa a chi può rifiutare e offri una ragione concreta, tira +Volontà.",
                "Accetta se mantieni la promessa o paghi il prezzo dichiarato.",
                "Serve una garanzia, una prova o un favore immediato.",
                "La tua leva si ritorce contro di te e segni 1 EXP.",
            ),
        ]
    )

    chapter(story, "04", "Mosse di combattimento", "Niente iniziativa numerica: il Master sposta il riflettore seguendo la fiction.")
    story.extend(
        [
            move_box(
                "ASSALIRE",
                "affronti un nemico pronto a reagire in mischia, tira +Volontà.",
                "Infliggi il tuo dado danno e scegli 1: +1d6 danno, eviti la risposta, crei un vantaggio per un alleato.",
                "Infliggi danno, ma il nemico risponde oppure ti mette in pericolo.",
                "Il nemico prende il controllo della situazione e segni 1 EXP.",
            ),
            Spacer(1, 6),
            move_box(
                "COLPIRE DA LONTANO",
                "attacchi a distanza mentre esiste pressione o rischio, tira +Materia.",
                "Infliggi il tuo dado danno da una posizione sicura.",
                "Infliggi danno e scegli 1: consumi munizioni, ti esponi, ottieni un effetto ridotto.",
                "Il colpo crea un problema serio e segni 1 EXP.",
            ),
            Spacer(1, 6),
            move_box(
                "DIFENDERE",
                "proteggi una persona, un oggetto o una posizione, tira +Resilienza.",
                "Ottieni 3 Prese.",
                "Ottieni 1 Presa.",
                "La minaccia oltrepassa la difesa e segni 1 EXP.",
            ),
            Spacer(1, 4),
            P("Spendi 1 Presa per dimezzare un danno, deviare un attacco su di te, aprire una via sicura o dare +1 al prossimo tiro di un alleato.", NOTE),
        ]
    )

    chapter(story, "05", "Danno, caduta e riposo", "Pochi tracciati, nessuna catena di percentuali durante il combattimento.")
    story.append(P("Danno e Armatura", H2))
    story.extend(
        bullets(
            [
                "Tira il dado danno del Ruolo. Il bersaglio sottrae la propria Armatura, minimo 0.",
                "Una minaccia minore infligge d4, una comune d6, una pericolosa d8, una terribile d10.",
                "Quando arrivi a 0 HP cadi e attivi Ultimo Respiro.",
            ]
        )
    )
    story.append(move_box("ULTIMO RESPIRO", "sei a 0 HP, tira 2d6 senza statistica.", "Ti rialzi con metà HP e il Master descrive come sei sopravvissuto.", "Resti vivo ma scegli: debito oscuro, menomazione temporanea o perdita importante.", "La morte ti reclama; il gruppo può tentare un ultimo patto impossibile."))
    story.append(P("Riposi", H2))
    story.append(
        data_table(
            ["Riposo", "Effetto semplice"],
            [
                ["Breve", "Se il luogo è sicuro, recupera 2 HP e 1 Oculum. Una sola volta per scena."],
                ["Lungo", "Porta gli HP almeno al 75% del massimo, ripristina tutto Oculum e riduci Cenere di 2."],
            ],
            [28, 144],
        )
    )
    story.append(P("Tabella pronta per il 75%", H2))
    story.append(data_table(["HP massimi", "Dopo il riposo lungo"], [["8", "6"], ["10", "8"], ["12", "9"], ["14", "11"], ["16", "12"]], [55, 117]))
    story.append(P("Il riposo non riduce mai gli HP di chi è già sopra la soglia.", NOTE))

    chapter(story, "06", "Ruoli pronti", "Scegli un Ruolo e inizia. Ogni Ruolo ha due mosse esclusive.")
    story.append(
        data_table(
            ["Ruolo", "HP", "Danno", "Arm.", "Dotazione"],
            [
                ["Guardiano", "12", "d10", "2", "arma pesante, scudo, armatura"],
                ["Esploratore", "10", "d8", "1", "arco, lama, corde, 3 munizioni"],
                ["Mistico", "8", "d6", "0", "focus, tomo, componenti, 4 Oculum"],
                ["Vincolatore", "10", "d6", "1", "simbolo, kit medico, arma leggera"],
            ],
            [39, 14, 18, 14, 87],
        )
    )
    role_rows = [
        ("Guardiano", "Muro vivente: quando Difendi ottieni +1 Presa. Colpo possente: su 10+ con Assalire puoi spingere, disarmare o spezzare una protezione."),
        ("Esploratore", "Passo leggero: la prima volta che entri in un luogo pericoloso chiedi una via sicura. Tiro preciso: spendi 1 munizione per ignorare Armatura."),
        ("Mistico", "Riserva profonda: inizi con 4 Oculum invece di 3. Visione runica: quando Percepisci magia, su 7+ fai sempre una domanda aggiuntiva."),
        ("Vincolatore", "Cura sul campo: una volta per scena ridai 1d6 HP a chi puoi toccare. Legame: quando Aiuti un alleato con cui hai un Legame, il bonus vale +2."),
    ]
    for name, text in role_rows:
        story.append(KeepTogether([P(name, H2), P(text)]))

    chapter(story, "07", "Oculum, Arti e Rune", "Il potere resta flessibile, ma il Lite non somma costi o DT.")
    story.append(P("Riserva Oculum", H2))
    story.append(P("Ogni personaggio possiede 3 Oculum, salvo capacità diverse. Spendi 1 Oculum quando una mossa o una formula lo richiede. I segnalini rendono la riserva immediata."))
    story.append(move_box("USARE UN'ARTE", "liberi un potere per cambiare davvero la scena, descrivi l'effetto e tira +Oculum.", "L'effetto avviene come descritto; scegli anche portata maggiore oppure nessun segno inquietante.", "L'effetto avviene, ma scegli 1: spendi 1 Oculum extra, durata breve, effetto ridotto, attiri attenzione.", "Il potere sfugge al controllo, il Master fa una mossa e segni 1 EXP."))
    story.append(P("Rune Art Lite", H2))
    story.extend(
        bullets(
            [
                "Le parole iniziali obbligatorie sono Self / Ally e Pulse; Intensità I e 1 azione sono sempre disponibili.",
                "Ogni Libro Runico insegna esattamente sei parole nuove. Se non esistono sei parole disponibili, il libro non viene consumato.",
                "Componi una frase con Target + Verbo e, se vuoi, Aspetto + Mod + Intensità + Durata + Trigger.",
                "Nel Lite le parole sono permessi narrativi: una formula normale costa 1 Oculum, una molto ampia o duratura 2, una decisiva 3. Decide il tavolo prima del tiro.",
            ]
        )
    )
    story.append(info_box("ESEMPIO", "Self / Ally + MEND + Vital + Pulse + I + 1 azione: curi te o un alleato vicino. Spendi 1 Oculum e usa la mossa Usare un'Arte.", CYAN))

    chapter(story, "08", "Esplorare il dungeon", "Una stanza interessante contiene sempre scelta, pericolo e conseguenza.")
    story.append(P("Ciclo di esplorazione", H2))
    story.extend(bullets(["Il Master descrive ciò che è evidente e chiede: cosa fate?", "I giocatori fanno domande e dichiarano azioni concrete.", "Se una mossa si attiva, si tira. Altrimenti la storia procede.", "Il Master mostra tracce del pericolo prima di colpire, salvo un 6- o una minaccia già stabilita."]))
    story.append(P("Preparare un dungeon in cinque righe", H2))
    story.append(data_table(["Elemento", "Scrivi una frase"], [["Scopo", "Perché vale la pena entrare?"], ["Pericolo", "Cosa peggiora se nessuno interviene?"], ["Tre luoghi", "Ingresso, cuore, profondità."], ["Abitanti", "Chi vive qui e cosa vuole?"], ["Ricompensa", "Informazione, alleato, reliquia o via nuova."]], [32, 140]))
    story.append(P("Scorte", H2))
    story.append(P("Usa tre tracciati di gruppo: Provviste, Torce e Munizioni, da 3 a 0. Un 7-9 o una mossa del Master può consumarne 1. A 0 la mancanza diventa un problema nella fiction."))
    story.append(P("Cenere Lite", H2))
    story.append(P("Segna Cenere da 0 a 6. A 3 o più hai -1 quando Resisti a fatica, fame o paura. A 6 crolli finché non ricevi aiuto o riposi in sicurezza."))

    chapter(story, "09", "Guida del Master", "Sii fan dei personaggi, riempi il mondo di meraviglia e rendi ogni scelta significativa.")
    story.append(P("Principi", H2))
    story.extend(bullets(["Descrivi il mondo come reale e in movimento.", "Mostra segnali di una minaccia prima delle conseguenze definitive.", "Dai un nome e un desiderio anche ai PNG minori.", "Fai domande provocatorie e usa le risposte.", "Non preparare una trama obbligatoria: prepara problemi e persone.", "Dopo ogni tua descrizione chiedi: cosa fate?"]))
    story.append(P("Mosse del Master", H2))
    story.append(data_table(["Quando", "Puoi..."], [["Su un 6-", "infliggere danno, separare, consumare una risorsa, rivelare una verità sgradita"], ["Quando aspettano", "mostrare un segnale, far avanzare un pericolo, offrire un'opportunità con costo"], ["Quando ignorano un rischio", "farlo accadere seguendo ciò che era già stato mostrato"], ["Dopo una vittoria", "mostrare il prezzo, una nuova pista o qualcosa che richiede una scelta"]], [46, 126]))
    story.append(info_box("MOSSA MORBIDA E MOSSA DURA", "Una mossa morbida annuncia il pericolo e lascia reagire. Una mossa dura applica la conseguenza. Usa una mossa dura dopo un 6-, quando il pericolo era chiaro o quando nessuno reagisce.", GOLD))

    chapter(story, "10", "Mostri e ricompense", "Un mostro richiede quattro dati e due frasi, non una scheda completa.")
    story.append(P("Creare un mostro", H2))
    story.append(data_table(["Tipo", "HP", "Danno", "Arm.", "Esempio"], [["Gregario", "3", "d4", "0", "ratto, cultista, sciame"], ["Comune", "6", "d6", "1", "goblin, non morto, predatore"], ["Elite", "10", "d8", "2", "cavaliere, orrore, guardiano"], ["Boss", "15", "d10", "2", "drago giovane, araldo, titano"]], [33, 17, 21, 15, 86]))
    story.append(P("Aggiungi sempre", H2))
    story.extend(bullets(["Istinto: ciò che il mostro vuole fare.", "Due mosse: azioni riconoscibili e pericolose.", "Due tag: volante, enorme, furtivo, magico, corazzato, sciame, distante, instabile.", "Una debolezza scopribile nella fiction."]))
    story.append(P("Ricompense senza contabilità", H2))
    story.append(data_table(["Ricompensa", "Effetto"], [["Consumabile", "Una volta: cura 1d6, annulla un pericolo o aggiungi +1d6 a un effetto."], ["Oggetto", "Concede un tag e una capacità narrativa chiara."], ["Titolo", "Una volta per sessione dà vantaggio quando la sua leggenda è rilevante."], ["Libro Runico", "Insegna sei parole nuove secondo le regole Rune Art Lite."], ["Informazione", "Rende possibile una via, un accordo o una vittoria prima impossibile."]], [38, 134]))

    chapter(story, "11", "EXP e fine sessione", "La crescita premia rischi, scoperte e legami, non i calcoli.")
    story.append(P("Segnare EXP", H2))
    story.extend(bullets(["Segna 1 EXP ogni volta che ottieni 6-.", "A fine sessione segna 1 EXP per ogni domanda a cui il gruppo risponde sì: avete scoperto qualcosa di importante? avete superato una minaccia notevole? avete rafforzato o complicato un Legame?"]))
    story.append(P("Avanzare", H2))
    story.append(P("Quando raggiungi 5 EXP, azzera il tracciato e scegli un avanzamento. Una statistica non può superare +3."))
    story.append(data_table(["Avanzamento", "Effetto"], [["Statistica", "+1 a una statistica, massimo +3."], ["Tenacia", "+2 HP massimi."], ["Talento", "Crea una nuova mossa con il Master."], ["Arte", "Ottieni un nuovo effetto affidabile per Usare un'Arte."], ["Legame", "Scrivi un nuovo Legame e cancella uno ormai risolto."], ["Retaggio", "Ottieni un contatto, un rifugio o un diritto nel mondo."]], [42, 130]))
    story.append(P("Fine della sessione", H2))
    story.extend(bullets(["Aggiornate EXP e Legami.", "Scrivete una minaccia ancora aperta.", "Scegliete chi riassumerà la sessione successiva.", "Il Master annota una conseguenza che avanzerà se nessuno interviene."]))

    chapter(story, "12", "Scheda e riferimento", "Questa pagina può essere stampata per ogni giocatore.")
    sheet = [
        [P("NOME", SHEET_LABEL), "", P("RUOLO", SHEET_LABEL), ""],
        ["", "", "", ""],
        [P("ASPETTO / ORIGINE", SHEET_LABEL), "", P("DESIDERIO", SHEET_LABEL), ""],
        ["", "", "", ""],
        [P("RESILIENZA", SHEET_LABEL), P("VOLONTÀ", SHEET_LABEL), P("MATERIA", SHEET_LABEL), P("OCULUM", SHEET_LABEL)],
        ["+____", "+____", "+____", "+____"],
        [P("HP", SHEET_LABEL), P("ARMATURA", SHEET_LABEL), P("DADO DANNO", SHEET_LABEL), P("CENERE", SHEET_LABEL)],
        ["____ / ____", "____", "d____", "____ / 6"],
        [P("LEGAME 1", SHEET_LABEL), "", P("LEGAME 2", SHEET_LABEL), ""],
        ["", "", "", ""],
        [P("MOSSE / ARTI", SHEET_LABEL), "", "", ""],
        ["", "", "", ""],
        ["", "", "", ""],
        [P("EQUIPAGGIAMENTO", SHEET_LABEL), "", P("EXP", SHEET_LABEL), ""],
        ["", "", "", "____ / 5"],
    ]
    sheet_row_heights = [6, 12, 6, 12, 7, 10, 7, 10, 7, 14, 7, 20, 20, 7, 15]
    sheet_table = Table(
        sheet,
        colWidths=[43 * mm] * 4,
        rowHeights=[height * mm for height in sheet_row_heights],
    )
    sheet_table.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.6, BLUE), ("SPAN", (0, 0), (1, 0)), ("SPAN", (2, 0), (3, 0)), ("SPAN", (0, 1), (1, 1)), ("SPAN", (2, 1), (3, 1)), ("SPAN", (0, 2), (1, 2)), ("SPAN", (2, 2), (3, 2)), ("SPAN", (0, 3), (1, 3)), ("SPAN", (2, 3), (3, 3)), ("SPAN", (0, 8), (1, 8)), ("SPAN", (2, 8), (3, 8)), ("SPAN", (0, 9), (1, 9)), ("SPAN", (2, 9), (3, 9)), ("SPAN", (0, 10), (3, 10)), ("SPAN", (0, 11), (3, 11)), ("SPAN", (0, 12), (3, 12)), ("SPAN", (0, 13), (2, 13)), ("SPAN", (0, 14), (2, 14)), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("BACKGROUND", (0, 0), (-1, -1), WHITE), ("LEFTPADDING", (0, 0), (-1, -1), 5)]))
    story.append(sheet_table)
    story.append(Spacer(1, 5 * mm))
    story.append(info_box("PROMEMORIA", "Tira 2d6 + Stat. 10+ riesci. 7-9 riesci con costo o scelta. 6- il Master fa una mossa e segni 1 EXP. Descrivi sempre cosa fai prima di scegliere la mossa.", INK))
    story.append(P("Questo manuale è una variante Lite autonoma di Oculum, pensata per tavoli che preferiscono un flusso fiction-first 2d6. Il regolamento completo dell'app resta separato.", NOTE))

    return story


def build_pdf(output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(output),
        pagesize=A4,
        rightMargin=19 * mm,
        leftMargin=19 * mm,
        topMargin=25 * mm,
        bottomMargin=17 * mm,
        title="Oculum Manuale Lite",
        author="Oculum",
        subject="Regolamento fiction-first 2d6 senza calcoli complessi",
    )
    doc.build(build_story(), onFirstPage=page_decoration, onLaterPages=page_decoration)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("output/pdf/Oculum_Manuale_Lite.pdf"),
    )
    args = parser.parse_args()
    build_pdf(args.output.resolve())
    print(args.output.resolve())


if __name__ == "__main__":
    main()
