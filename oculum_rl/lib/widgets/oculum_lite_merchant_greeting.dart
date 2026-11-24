import 'dart:math';

import 'package:flutter/material.dart';

enum LiteShopkeeper {
  goblin('Il goblin del ferro vecchio', [
    'Oh, un cliente! Aspetta, ero io il cliente? No. Tu hai gli Obser.',
    'Benvenuto! Se vedi una vite che cammina, lasciala stare. È il contabile.',
    'Ti faccio uno sconto se… se… guarda, quella mosca vola al contrario!',
    'Ehi. Vendi o compri? Avevo un terzo verbo ma l’ho prestato a una mosca.',
    'Tocca pure la merce. Se ti tocca lei, alza prima il prezzo.',
    'Oggi sono lucidissimo. Ho messo le monete in tasca e i pantaloni li ho quasi trovati.',
  ]),
  armaiola('L’armaiola itinerante', [
    'Avvicinati. Le armi mordono solo se glielo chiedi bene.',
    'Hai fatto molta strada. Vediamo che cosa ti farà tornare intero.',
    'Cerca l’equilibrio nell’impugnatura. Il resto lo farà il braccio.',
    'Ben trovato. Ho lama, polvere e qualche sorpresa sigillata.',
    'Scegli una compagna di viaggio. Quella lunga vuole spazio.',
    'Se cerchi una presa più salda, posso farti provare questa.',
  ]),
  taverniera('La taverniera', [
    'Giù lo zaino. Hai l’aria di chi ha saltato la cena e un paio di funerali.',
    'Siediti, viandante. Lo stufato ribolle da prima della tua missione.',
    'Prima mangi, poi mi dici chi ti ha ridotto così.',
    'Entra pure. La zuppa è calda e le sedie sono quasi tutte intere.',
    'Pane, brodo o qualcosa che ti scaldi fino al prossimo piano?',
    'Le scodelle tornano qui. Le ossa, se sono tue, puoi tenerle.',
  ]),
  fabbro('Il fabbro', [
    'Metti la lama sul banco. Il ferro dice subito dove hai sbagliato.',
    'Ehilà. Cerchi qualcosa da lanciare o qualcosa che torni indietro?',
    'Vieni avanti. Ho lasciato raffreddare il meglio per te.',
    'Qui guardiamo il filo, il peso e le mani che devono reggerli.',
    'Salute. Appoggia gli Obser vicino alla morsa.',
    'Senti come canta quel metallo? Quello è pronto per il viaggio.',
  ]),
  veggente('La veggente', [
    'Ti ho già visto arrivare. O forse ti ho visto partire la prossima volta.',
    'Vieni. I ricordi più ostinati hanno bisogno di un posto dove aspettare.',
    'Porti con te un acquisto che vale la pena ricordare?',
    'Guarda la candela. Tra poco ti mostrerà ciò che hai appena comprato.',
    'Ben tornato. Alcuni futuri cominciano da un piccolo oggetto sul banco.',
    'Siediti. Dimmi che cosa vuoi ritrovare quando il sentiero ricomincerà.',
  ]);

  const LiteShopkeeper(this.label, this.greetings);

  final String label;
  final List<String> greetings;
}

class LiteMerchantGreeting extends StatefulWidget {
  const LiteMerchantGreeting({
    super.key,
    required this.shopkeeper,
    required this.playVoice,
  });

  final LiteShopkeeper shopkeeper;
  final ValueChanged<String> playVoice;

  @override
  State<LiteMerchantGreeting> createState() => _LiteMerchantGreetingState();
}

class _LiteMerchantGreetingState extends State<LiteMerchantGreeting> {
  final _random = Random();
  int _line = 0;

  @override
  void initState() {
    super.initState();
    _line = _random.nextInt(widget.shopkeeper.greetings.length);
    final firstSpeaker = widget.shopkeeper;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.shopkeeper == firstSpeaker) _speak();
    });
  }

  void _speak() =>
      widget.playVoice('voce-${widget.shopkeeper.name}-${_line % 3 + 1}');

  void _nextGreeting() {
    final count = widget.shopkeeper.greetings.length;
    setState(() => _line = (_line + 1 + _random.nextInt(count - 1)) % count);
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.shopkeeper.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 3),
              Semantics(
                liveRegion: true,
                child: Text(
                  '«${widget.shopkeeper.greetings[_line]}»',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _nextGreeting,
          icon: const Icon(Icons.record_voice_over_outlined),
          tooltip: 'Parla con ${widget.shopkeeper.label.toLowerCase()}',
        ),
      ],
    );
  }
}
