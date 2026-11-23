part of '../../main.dart';

typedef _OculumMarketProfileChange = ({String name, Color color, bool ping});

class _OculumMarketSphere extends StatelessWidget {
  const _OculumMarketSphere({
    super.key,
    required this.name,
    required this.actionLabel,
    required this.color,
    required this.onPressed,
    this.isSelf = false,
  });

  final String name;
  final String actionLabel;
  final Color color;
  final VoidCallback onPressed;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final shade = color.withValues(alpha: 1);
    final light = Color.lerp(shade, Colors.white, .42)!;
    final shadow = Color.lerp(shade, Colors.black, .74)!;
    return Tooltip(
      message: actionLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Ink(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-.38, -.44),
                        radius: 1.05,
                        colors: [light, shade, shadow],
                      ),
                      border: Border.all(color: light.withValues(alpha: .72)),
                    ),
                    child: Icon(
                      isSelf ? Icons.edit_outlined : Icons.storefront_outlined,
                      color: shade.computeLuminance() >= .45
                          ? Colors.black87
                          : Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OculumMarketSpheres extends StatelessWidget {
  const _OculumMarketSpheres({required this.spheres});

  final List<_OculumMarketSphere> spheres;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final sphere in spheres)
          Padding(padding: const EdgeInsets.only(right: 4), child: sphere),
      ],
    ),
  );
}

class _OculumMarketProfileDialog extends StatefulWidget {
  const _OculumMarketProfileDialog({
    required this.name,
    required this.fallbackName,
    required this.color,
    required this.connected,
    required this.translate,
  });

  final String name;
  final String fallbackName;
  final Color color;
  final bool connected;
  final String Function(String, String) translate;

  @override
  State<_OculumMarketProfileDialog> createState() =>
      _OculumMarketProfileDialogState();
}

class _OculumMarketProfileDialogState
    extends State<_OculumMarketProfileDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.name.trim().isEmpty ? widget.fallbackName : widget.name,
  );
  late Color _color = widget.color;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => OculumStatColorPicker(
        initial: _color,
        label: widget.translate('Colore della sfera', 'Sphere colour'),
      ),
    );
    if (mounted && color != null) setState(() => _color = color);
  }

  void _finish({required bool ping}) =>
      Navigator.pop<_OculumMarketProfileChange>(context, (
        name: _name.text.trim(),
        color: _color,
        ping: ping,
      ));

  @override
  Widget build(BuildContext context) {
    final t = widget.translate;
    final hasName = _name.text.trim().isNotEmpty;
    return AlertDialog(
      key: const ValueKey('online_market_profile_dialog'),
      backgroundColor: const Color(0xFF0D0C13),
      scrollable: true,
      title: Text(t('La tua sfera', 'Your sphere')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('online_market_profile_name'),
              controller: _name,
              maxLength: 80,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: t('Nome Online', 'Online name'),
                hintText: widget.fallbackName,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t(
                'Il ping aggiorna il nome mostrato Online.',
                'A ping updates the name shown online.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('online_market_profile_colour'),
              onPressed: _pickColor,
              icon: Icon(Icons.circle, color: _color.withValues(alpha: 1)),
              label: Text(
                t(
                  'Colore RGB / HEX · ${oculumColorHex(_color)}',
                  'RGB / HEX colour · ${oculumColorHex(_color)}',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Annulla', 'Cancel')),
        ),
        OutlinedButton.icon(
          key: const ValueKey('online_market_profile_ping'),
          onPressed: widget.connected && hasName
              ? () => _finish(ping: true)
              : null,
          icon: const Icon(Icons.sensors_outlined),
          label: const Text('Ping'),
        ),
        FilledButton(
          key: const ValueKey('online_market_profile_save'),
          onPressed: hasName ? () => _finish(ping: false) : null,
          child: Text(t('Salva', 'Save')),
        ),
      ],
    );
  }
}

typedef _OculumMarketText = String Function(String, String);
typedef _OculumMarketNumber = ({String label, int initial, int min, int? max});

class _OculumMarketNumbersDialog extends StatefulWidget {
  const _OculumMarketNumbersDialog({
    required this.title,
    required this.action,
    required this.fields,
    required this.translate,
    this.caption,
  });

  final String title;
  final String action;
  final String? caption;
  final List<_OculumMarketNumber> fields;
  final _OculumMarketText translate;

  @override
  State<_OculumMarketNumbersDialog> createState() =>
      _OculumMarketNumbersDialogState();
}

class _OculumMarketNumbersDialogState
    extends State<_OculumMarketNumbersDialog> {
  final _form = GlobalKey<FormState>();
  late final _values = [for (final field in widget.fields) field.initial];

  void _submit() {
    final form = _form.currentState!;
    if (!form.validate()) return;
    form.save();
    Navigator.pop(context, _values);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.translate;
    return AlertDialog(
      backgroundColor: const Color(0xFF0D0C13),
      scrollable: true,
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.caption != null) Text(widget.caption!),
              for (final (index, field) in widget.fields.indexed)
                TextFormField(
                  initialValue: '${field.initial}',
                  keyboardType: TextInputType.number,
                  textInputAction: index == widget.fields.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(labelText: field.label),
                  validator: (text) {
                    final value = int.tryParse(text?.trim() ?? '');
                    final maxValue = field.max;
                    if (value != null &&
                        value >= field.min &&
                        (maxValue == null || value <= maxValue)) {
                      return null;
                    }
                    if (maxValue == null) {
                      return t(
                        'Inserisci un valore da ${field.min} in su.',
                        'Enter a value of at least ${field.min}.',
                      );
                    }
                    return t(
                      'Inserisci un valore da ${field.min} a ${field.max}.',
                      'Enter a value from ${field.min} to ${field.max}.',
                    );
                  },
                  onSaved: (text) => _values[index] = int.parse(text!.trim()),
                  onFieldSubmitted: (_) {
                    if (index == widget.fields.length - 1) _submit();
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Annulla', 'Cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.action)),
      ],
    );
  }
}

class _OculumPersonalShopDialog extends StatefulWidget {
  const _OculumPersonalShopDialog({
    required this.title,
    required this.translate,
    required this.resolveView,
    required this.changes,
    required this.readNumber,
    this.inventory,
    this.balance,
    this.onList,
    this.onBuy,
    this.onCancel,
    this.onDiscount,
  });

  final String title;
  final _OculumMarketText translate;
  final Map<String, dynamic>? Function() resolveView;
  final Listenable changes;
  final int Function(dynamic value) readNumber;
  final List<InventoryItem> Function()? inventory;
  final int Function()? balance;
  final Future<bool> Function(InventoryItem item, int quantity, int price)?
  onList;
  final Future<bool> Function(String offerId, int quantity, int price)? onBuy;
  final Future<bool> Function(String offerId)? onCancel;
  final Future<bool> Function(String offerId, int price)? onDiscount;

  @override
  State<_OculumPersonalShopDialog> createState() =>
      _OculumPersonalShopDialogState();
}

class _OculumPersonalShopDialogState extends State<_OculumPersonalShopDialog> {
  bool _busy = false;
  String? _message;

  Future<void> _submit(Future<bool> Function() operation) async {
    if (_busy || !mounted || widget.resolveView() == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    var sent = false;
    try {
      sent = await operation();
    } on Exception {
      sent = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = sent
          ? widget.translate('Richiesta registrata.', 'Request registered.')
          : widget.translate('Richiesta non riuscita.', 'Request failed.');
    });
  }

  Future<List<int>?> _numbers({
    required String title,
    required String action,
    required List<_OculumMarketNumber> fields,
    String? caption,
  }) => showDialog<List<int>>(
    context: context,
    builder: (_) => _OculumMarketNumbersDialog(
      title: title,
      action: action,
      fields: fields,
      caption: caption,
      translate: widget.translate,
    ),
  );

  Future<void> _listItem() async {
    final t = widget.translate;
    final items = widget.inventory!();
    final item = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0C13),
        title: Text(t('Metti in vendita', 'List an item')),
        content: SizedBox(
          width: 370,
          height: min(350, MediaQuery.sizeOf(context).height * .53),
          child: items.isEmpty
              ? Center(
                  child: Text(
                    t('Nessun oggetto disponibile.', 'No items available.'),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.nome),
                      trailing: Text('×${item.quantita}'),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Annulla', 'Cancel')),
          ),
        ],
      ),
    );
    if (!mounted || item == null || item.quantita <= 0) return;
    final values = await _numbers(
      title: item.nome,
      action: t('Metti in vendita', 'List for sale'),
      fields: [
        (
          label: t('Quantità', 'Quantity'),
          initial: 1,
          min: 1,
          max: item.quantita,
        ),
        (
          label: t('Obser per unità', 'Obser per item'),
          initial: 1,
          min: 0,
          max: null,
        ),
      ],
    );
    if (values != null) {
      await _submit(() => widget.onList!(item, values[0], values[1]));
    }
  }

  Future<void> _buy(String id, String name, int quantity, int price) async {
    final t = widget.translate;
    final values = await _numbers(
      title: name,
      action: t('Acquista', 'Buy'),
      caption: t('$price Obser per unità', '$price Obser per item'),
      fields: [
        (label: t('Quantità', 'Quantity'), initial: 1, min: 1, max: quantity),
      ],
    );
    if (values != null) {
      await _submit(() => widget.onBuy!(id, values.single, price));
    }
  }

  Future<void> _discount(String id, String name, int price) async {
    final t = widget.translate;
    final values = await _numbers(
      title: name,
      action: t('Applica sconto', 'Apply discount'),
      caption: t('Prezzo attuale $price Obser', 'Current price $price Obser'),
      fields: [
        (
          label: t('Nuovo prezzo unitario', 'New unit price'),
          initial: price - 1,
          min: 0,
          max: price - 1,
        ),
      ],
    );
    if (values != null) {
      await _submit(() => widget.onDiscount!(id, values.single));
    }
  }

  Widget _offerTile(Map<dynamic, dynamic> offer) {
    final t = widget.translate;
    final id = '${offer['id'] ?? ''}';
    final item = offer['item'];
    final name = item is Map ? '${item['nome'] ?? ''}'.trim() : '';
    final quantity = widget.readNumber(offer['quantity']);
    final price = widget.readNumber(offer['unitPrice']);
    if (id.isEmpty || name.isEmpty || quantity <= 0 || price < 0) {
      return const SizedBox.shrink();
    }
    final affordable = price == 0
        ? quantity
        : min(quantity, max(0, widget.balance?.call() ?? 0) ~/ price);
    return ListTile(
      key: ValueKey('online_market_offer_$id'),
      title: Text(name),
      subtitle: Text('×$quantity · $price Obser'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onBuy != null)
            IconButton(
              onPressed: _busy || affordable <= 0
                  ? null
                  : () => _buy(id, name, affordable, price),
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: t('Acquista', 'Buy'),
            ),
          if (widget.onCancel != null)
            IconButton(
              onPressed: _busy
                  ? null
                  : () => _submit(() => widget.onCancel!(id)),
              icon: const Icon(Icons.undo_outlined),
              tooltip: t('Ritira offerta', 'Withdraw offer'),
            ),
          if (widget.onDiscount != null && price > 0)
            IconButton(
              onPressed: _busy ? null : () => _discount(id, name, price),
              icon: const Icon(Icons.percent),
              tooltip: t('Applica sconto', 'Apply discount'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.changes,
    builder: (context, _) {
      final t = widget.translate;
      final view = widget.resolveView();
      final rawOffers = view?['offers'];
      final offers = rawOffers is List
          ? rawOffers.whereType<Map>().toList()
          : const <Map>[];
      return AlertDialog(
        key: const ValueKey('online_market_shop_dialog'),
        backgroundColor: const Color(0xFF0D0C13),
        title: Text(widget.title),
        content: SizedBox(
          width: 560,
          height: min(450, MediaQuery.sizeOf(context).height * .57),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_message != null) Text(_message!),
              Expanded(
                child: offers.isEmpty
                    ? Center(
                        child: Text(
                          view == null
                              ? t(
                                  'Negozio non disponibile.',
                                  'Shop unavailable.',
                                )
                              : t('Nessuna offerta.', 'No offers.'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: offers.length,
                        itemBuilder: (_, index) => _offerTile(offers[index]),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Chiudi', 'Close')),
          ),
          if (widget.onList != null && view != null)
            FilledButton.icon(
              key: const ValueKey('online_market_list_item'),
              onPressed: _busy ? null : _listItem,
              icon: const Icon(Icons.add_box_outlined),
              label: Text(t('Metti in vendita', 'List for sale')),
            ),
        ],
      );
    },
  );
}

class _OculumMarketSalesDialog extends StatefulWidget {
  const _OculumMarketSalesDialog({
    required this.translate,
    required this.readNumber,
    required this.readSales,
    required this.changes,
    required this.onDiscount,
  });

  final _OculumMarketText translate;
  final int Function(dynamic value) readNumber;
  final List<Map<String, dynamic>> Function() readSales;
  final Listenable changes;
  final Future<bool> Function(String saleId, int total) onDiscount;

  @override
  State<_OculumMarketSalesDialog> createState() =>
      _OculumMarketSalesDialogState();
}

class _OculumMarketSalesDialogState extends State<_OculumMarketSalesDialog> {
  bool _busy = false;
  String? _message;

  Future<void> _discountSale(String id, String name, int total) async {
    final t = widget.translate;
    final values = await showDialog<List<int>>(
      context: context,
      builder: (_) => _OculumMarketNumbersDialog(
        title: name,
        action: t('Applica sconto', 'Apply discount'),
        caption: t('Totale attuale $total Obser', 'Current total $total Obser'),
        fields: [
          (
            label: t('Nuovo totale', 'New total'),
            initial: total - 1,
            min: 0,
            max: total - 1,
          ),
        ],
        translate: t,
      ),
    );
    if (!mounted || values == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    var result = false;
    try {
      result = await widget.onDiscount(id, values.single);
    } on Exception {
      result = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result
          ? t('Richiesta registrata.', 'Request registered.')
          : t('Richiesta non riuscita.', 'Request failed.');
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.changes,
    builder: (context, _) {
      final t = widget.translate;
      final sales = widget.readSales();
      return AlertDialog(
        key: const ValueKey('online_market_sales_dialog'),
        backgroundColor: const Color(0xFF0D0C13),
        title: Text(t('Vendite Online', 'Online sales')),
        content: SizedBox(
          width: 560,
          height: min(450, MediaQuery.sizeOf(context).height * .57),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_message != null) Text(_message!),
              Expanded(
                child: sales.isEmpty
                    ? Center(
                        child: Text(
                          t(
                            'Nessuna vendita registrata.',
                            'No sales recorded.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sales.length,
                        itemBuilder: (_, index) {
                          final sale = sales[index];
                          final id = '${sale['id'] ?? ''}';
                          final item = '${sale['itemName'] ?? ''}';
                          final quantity = widget.readNumber(sale['quantity']);
                          final total = widget.readNumber(
                            sale['effectiveTotal'],
                          );
                          final refunded = widget.readNumber(sale['refunded']);
                          return ListTile(
                            key: ValueKey('online_market_sale_$id'),
                            title: Text(item),
                            subtitle: Text(
                              refunded > 0
                                  ? t(
                                      '×$quantity · $total Obser · $refunded restituiti',
                                      '×$quantity · $total Obser · $refunded refunded',
                                    )
                                  : '×$quantity · $total Obser',
                            ),
                            trailing: IconButton(
                              onPressed: _busy || id.isEmpty || total <= 0
                                  ? null
                                  : () => _discountSale(id, item, total),
                              icon: const Icon(Icons.percent),
                              tooltip: t(
                                'Sconto sulla vendita',
                                'Discount sale',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      );
    },
  );
}

extension _OculumPersonalMarketUi on _OculumHomePageState {
  bool get _canModeratePersonalMarket =>
      realtimeService?.isConnected == true &&
      realtimeService?.authenticatedRole == 'master';

  ({String? account, String scope}) get _personalMarketUiScope =>
      (account: realtimeService?.authenticatedUserId, scope: permissionScope);

  Map<String, dynamic>? _publicPersonalShop(String ownerTag) =>
      onlineMarketParticipants
          .where((shop) => shop['ownerTag'] == ownerTag)
          .firstOrNull;

  Future<void> _editPersonalMarketSphere() async {
    final originalScope = _personalMarketUiScope;
    final change = await showDialog<_OculumMarketProfileChange>(
      context: context,
      builder: (_) => _OculumMarketProfileDialog(
        name: realtimeNameController.text,
        fallbackName: realtimeDisplayName(),
        color: localOnlineMarketOrbColor,
        connected: realtimeService?.isConnected == true,
        translate: t,
      ),
    );
    if (!mounted || change == null || originalScope != _personalMarketUiScope) {
      return;
    }
    final updated = await updateLocalOnlineMarketOrb(
      name: change.name,
      color: change.color,
    );
    if (!mounted || originalScope != _personalMarketUiScope) return;
    if (!updated) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Aggiornamento della sfera non riuscito.',
              'Sphere update failed.',
            ),
          ),
        ),
      );
    } else if (change.ping) {
      sendRealtimePing();
    }
  }

  Future<void> _openPersonalMarketShop(
    String ownerTag,
    String title, {
    bool own = false,
    bool privateMaster = false,
  }) async {
    final originalScope = _personalMarketUiScope;
    Map<String, dynamic>? resolveView() {
      if (originalScope != _personalMarketUiScope) return null;
      if (own && localPersonalMarketOwnerTag != ownerTag) return null;
      if (privateMaster) {
        return _canModeratePersonalMarket ? privateMasterMarketView : null;
      }
      return _publicPersonalShop(ownerTag);
    }

    if (!mounted || resolveView() == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _OculumPersonalShopDialog(
        title: title,
        translate: t,
        resolveView: resolveView,
        changes: onlinePersonalMarketRevision,
        readNumber: readIntValue,
        inventory: own
            ? () => inventario
                  .where((item) => item.quantita > 0 && !item.equipaggiata)
                  .toList()
            : null,
        balance: own ? null : () => leggiNumero(obserController),
        onList: own
            ? (item, quantity, price) => requestPersonalMarketOperation(
                'list',
                item: item,
                quantity: quantity,
                unitPrice: price,
              )
            : null,
        onBuy: own
            ? null
            : (id, quantity, price) => requestPersonalMarketOperation(
                'buy',
                offerId: id,
                quantity: quantity,
                unitPrice: price,
              ),
        onCancel: own
            ? (id) => requestPersonalMarketOperation('cancel', offerId: id)
            : null,
        onDiscount: _canModeratePersonalMarket
            ? (id, price) => requestPersonalMarketOperation(
                'discountOffer',
                offerId: id,
                unitPrice: price,
              )
            : null,
      ),
    );
  }

  Future<void> _showPersonalMarketSales() async {
    final originalScope = _personalMarketUiScope;
    bool canReadSales() =>
        _canModeratePersonalMarket && originalScope == _personalMarketUiScope;
    if (!canReadSales()) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _OculumMarketSalesDialog(
        translate: t,
        readNumber: readIntValue,
        changes: onlinePersonalMarketRevision,
        readSales: () => canReadSales()
            ? onlinePersonalMarketSales
            : const <Map<String, dynamic>>[],
        onDiscount: (id, total) async =>
            canReadSales() &&
            await requestPersonalMarketOperation(
              'discountSale',
              saleId: id,
              adjustedTotal: total,
            ),
      ),
    );
  }

  Widget personalMarketSpheresHeader() => ListenableBuilder(
    listenable: onlinePersonalMarketRevision,
    builder: (context, _) {
      final ownerTag = localPersonalMarketOwnerTag;
      final privateMaster =
          _canModeratePersonalMarket && privateMasterMarketView != null;
      final canViewOwnShop =
          privateMaster || _publicPersonalShop(ownerTag) != null;
      final ownShopTitle = privateMaster
          ? t('Mercato personale del Master', 'Private Master shop')
          : t('Il tuo negozio', 'Your shop');
      final spheres = [
        _OculumMarketSphere(
          key: const ValueKey('online_market_self_sphere'),
          name: realtimeDisplayName(),
          actionLabel: t('Modifica la tua sfera', 'Edit your sphere'),
          color: localOnlineMarketOrbColor,
          onPressed: _editPersonalMarketSphere,
          isSelf: true,
        ),
      ];
      for (final peer in onlineMarketParticipants) {
        final tag = '${peer['ownerTag'] ?? ''}';
        final name = '${peer['name'] ?? peer['ownerName'] ?? ''}'.trim();
        if (tag.isEmpty || tag == ownerTag || name.isEmpty) continue;
        final shopTitle = t('Negozio di $name', '$name’s shop');
        spheres.add(
          _OculumMarketSphere(
            key: ValueKey('online_market_sphere_$tag'),
            name: name,
            actionLabel: shopTitle,
            color: Color(
              readIntValue(
                peer['argb'],
                fallback: const Color(0xFF7B61FF).toARGB32(),
              ),
            ),
            onPressed: () => _openPersonalMarketShop(tag, shopTitle),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _OculumMarketSpheres(spheres: spheres),
          if (canViewOwnShop || _canModeratePersonalMarket)
            Wrap(
              spacing: 4,
              children: [
                if (canViewOwnShop)
                  TextButton.icon(
                    key: const ValueKey('online_market_own_shop'),
                    onPressed: () => _openPersonalMarketShop(
                      ownerTag,
                      ownShopTitle,
                      own: true,
                      privateMaster: privateMaster,
                    ),
                    icon: const Icon(Icons.storefront_outlined, size: 17),
                    label: Text(ownShopTitle),
                  ),
                if (_canModeratePersonalMarket)
                  TextButton.icon(
                    key: const ValueKey('online_market_sales'),
                    onPressed: _showPersonalMarketSales,
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: Text(t('Vendite Online', 'Online sales')),
                  ),
              ],
            ),
        ],
      );
    },
  );
}
