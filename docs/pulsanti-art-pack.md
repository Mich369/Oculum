# Pulsanti Oculum: cornici e materiali condivisi

Il livello `OculumArtButtonLayer` viene applicato attraverso i temi Material a
TextButton, ElevatedButton, OutlinedButton, FilledButton e IconButton. Le azioni,
i FocusNode, le dimensioni, le icone e le etichette restano sul controllo nativo.
Le cornici non intercettano puntatori e non aggiungono descrizioni duplicate.

Ogni Art Pack include cinque PNG trasparenti separati e senza testo:
`frames/button-normal.png`, `button-hover.png`, `button-pressed.png`,
`button-selected.png`, `button-disabled.png`. Sono esportazioni delle cornici
grafiche esistenti, con trattamento luminoso distinto per stato, non nuovi
concept indipendenti. Il centro trasparente protegge la leggibilità.

Le immagini sono 1024×512; il nine-slice usa la geometria interna 128,64–896,448
e scala 8, aumentata automaticamente nei controlli molto compatti, per proteggere
gli angoli anche nei pulsanti piccoli. Le texture dei
materiali sono caricate dalla stessa famiglia del tema e tenute poco visibili
sotto il contenuto. La cache Flutter riusa le immagini; RepaintBoundary isola
il livello grafico. Non c'è un controller di animazione per ogni pulsante.

Con il tema automatico del combattimento attivo, il materiale segue la famiglia
del danno dominante già calcolato dal sistema esistente: Fuoco usa Ember Rite,
Fisico il ferro nero. Il cambio è solo grafico. I pulsanti ascoltano direttamente
il controller, senza ricostruire la scheda per animare hover e pressione.

Personalizzabili: tutti i PNG dei cinque stati, le texture dei materiali,
la mappatura dei pack, la scala della cornice, la trasparenza della texture,
la palette e il tema automatico già presente nelle impostazioni. Per rigenerare
i PNG dai pannelli originali eseguire `dart run scripts/build_button_art.dart`.
Modificare una cornice richiede di conservarne dimensioni e centro trasparente.

La navigazione inferiore usa `OculumArtInkWell`, lo stesso livello decorativo
con gli stati nativi del suo InkWell. Gli altri controlli disegnati interamente
con GestureDetector/InkWell/CustomPaint possono adottare esplicitamente questo
componente: non ereditano automaticamente i temi ButtonStyle.
