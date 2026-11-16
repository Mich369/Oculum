import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OculumAccountProfile {
  const OculumAccountProfile({
    required this.userId,
    required this.username,
    required this.publicCode,
  });

  factory OculumAccountProfile.fromJson(Map<String, dynamic> json) {
    return OculumAccountProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      publicCode: json['public_code'] as String?,
    );
  }

  final String userId;
  final String username;
  final String? publicCode;
}

abstract interface class OculumAccountProfileBackend {
  Future<OculumAccountProfile?> fetch(String accountId);

  Future<OculumAccountProfile> claim(
    String accountId, {
    String? username,
    String? publicCode,
  });
}

class SupabaseOculumAccountProfileBackend
    implements OculumAccountProfileBackend {
  const SupabaseOculumAccountProfileBackend(this._client);

  static const _requestTimeout = Duration(seconds: 20);

  final SupabaseClient _client;

  void _checkSession(String accountId) {
    if (_client.auth.currentUser?.id != accountId) {
      throw const _AccountChanged();
    }
  }

  @override
  Future<OculumAccountProfile?> fetch(String accountId) async {
    _checkSession(accountId);
    final data = await _client
        .from('oculum_account_profiles')
        .select('user_id, username, public_code')
        .eq('user_id', accountId)
        .maybeSingle()
        .timeout(_requestTimeout);
    _checkSession(accountId);
    return data == null ? null : OculumAccountProfile.fromJson(data);
  }

  @override
  Future<OculumAccountProfile> claim(
    String accountId, {
    String? username,
    String? publicCode,
  }) async {
    _checkSession(accountId);
    final data = await _client
        .rpc<Map<String, dynamic>>(
          'oculum_claim_account_profile',
          params: {
            'p_expected_user_id': accountId,
            'p_username': username,
            'p_public_code': publicCode,
          },
        )
        .timeout(_requestTimeout);
    _checkSession(accountId);
    return OculumAccountProfile.fromJson(data);
  }
}

class _AccountChanged implements Exception {
  const _AccountChanged();
}

class OculumAccountProfilePanel extends StatefulWidget {
  const OculumAccountProfilePanel({
    super.key,
    required this.accountId,
    required this.canClaimPublicCode,
    required this.backend,
  });

  factory OculumAccountProfilePanel.supabase({
    Key? key,
    required String accountId,
    required bool canClaimPublicCode,
  }) {
    return OculumAccountProfilePanel(
      key: key,
      accountId: accountId,
      canClaimPublicCode: canClaimPublicCode,
      backend: SupabaseOculumAccountProfileBackend(Supabase.instance.client),
    );
  }

  final String accountId;
  final bool canClaimPublicCode;
  final OculumAccountProfileBackend backend;

  @override
  State<OculumAccountProfilePanel> createState() =>
      _OculumAccountProfilePanelState();
}

class _OculumAccountProfilePanelState extends State<OculumAccountProfilePanel> {
  static final _outerSpaces = RegExp(r'^ +| +$');
  static final _controls = RegExp(r'[\x00-\x1f\x7f-\x9f]');
  static final _codePattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{2,23}$');

  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _publicCode = TextEditingController();
  OculumAccountProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _reloadRequired = false;
  String? _message;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant OculumAccountProfilePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId == widget.accountId) return;
    _username.clear();
    _publicCode.clear();
    _profile = null;
    _saving = false;
    _fetch();
  }

  @override
  void dispose() {
    _username.dispose();
    _publicCode.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final generation = ++_generation;
    final accountId = widget.accountId;
    setState(() {
      _loading = true;
      _reloadRequired = false;
      _message = null;
    });
    try {
      final profile = await widget.backend.fetch(accountId);
      if (!mounted || generation != _generation) return;
      if (profile != null && profile.userId != accountId) {
        throw const _AccountChanged();
      }
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _reloadRequired = true;
        _message = _errorMessage(error);
      });
    }
  }

  String _normalize(String value) => value.replaceAll(_outerSpaces, '');

  String? _validateUsername(String? value) {
    final username = _normalize(value ?? '');
    if (username.isEmpty) return 'Inserisci un nome utente.';
    if (username.runes.length > 40 || _controls.hasMatch(username)) {
      return 'Usa al massimo 40 caratteri di testo.';
    }
    return null;
  }

  String? _validateCode(String? value) {
    final code = _normalize(value ?? '');
    if (code.isEmpty || _codePattern.hasMatch(code)) return null;
    return 'Usa da 3 a 24 lettere, numeri, trattini o underscore. '
        'Inizia con una lettera o un numero.';
  }

  String _errorMessage(Object error) => switch (error) {
    _AccountChanged() => 'L’account è cambiato. Ricarica il profilo.',
    PostgrestException(code: '23505') => 'Questo codice pubblico è già in uso.',
    PostgrestException(code: '42501') =>
      'Verifica l’email o accedi di nuovo per salvare il profilo.',
    PostgrestException(code: '22023') =>
      'Controlla i campi o ricarica il profilo se lo hai già salvato.',
    PostgrestException(code: 'PGRST202' || 'PGRST205' || '42P01') =>
      'Il profilo pubblico è temporaneamente indisponibile.',
    _ =>
      'Impossibile aggiornare il profilo. Controlla la connessione e riprova.',
  };

  Future<void> _save() async {
    if (_loading || _saving || _reloadRequired) return;
    if (_form.currentState?.validate() != true) return;

    final username = _profile == null ? _normalize(_username.text) : null;
    final enteredCode = _normalize(_publicCode.text);
    final publicCode =
        widget.canClaimPublicCode &&
            _profile?.publicCode == null &&
            enteredCode.isNotEmpty
        ? enteredCode
        : null;
    if (username == null && publicCode == null) return;

    final generation = _generation;
    final accountId = widget.accountId;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final profile = await widget.backend.claim(
        accountId,
        username: username,
        publicCode: publicCode,
      );
      if (!mounted || generation != _generation) return;
      if (profile.userId != accountId) throw const _AccountChanged();
      if (publicCode != null) _publicCode.clear();
      setState(() {
        _profile = profile;
        _saving = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      // A lost response may have followed a successful claim. Reload first.
      final canRetry = error is PostgrestException && error.code == '23505';
      setState(() {
        _saving = false;
        _reloadRequired = !canRetry;
        _message = _errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final canEdit = !_loading && !_reloadRequired;
    final showCodeField =
        canEdit && widget.canClaimPublicCode && profile?.publicCode == null;
    final showSave = canEdit && (profile == null || showCodeField);

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profilo pubblico',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (_loading) const LinearProgressIndicator(),
          if (profile != null)
            SelectableText('Nome utente: ${profile.username}'),
          if (profile?.publicCode case final code?)
            SelectableText('Codice pubblico del profilo: $code'),
          if (canEdit && profile == null)
            TextFormField(
              controller: _username,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nome utente'),
              validator: _validateUsername,
            ),
          if (showCodeField)
            TextFormField(
              controller: _publicCode,
              enabled: !_saving,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Codice pubblico del profilo',
                helperText: 'Facoltativo. Da 3 a 24 caratteri.',
              ),
              validator: _validateCode,
            ),
          if (canEdit &&
              !widget.canClaimPublicCode &&
              profile?.publicCode == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Verifica l’email per scegliere il codice pubblico.'),
            ),
          if (showSave) ...[
            const SizedBox(height: 6),
            const Text('Le scelte diventano definitive al salvataggio.'),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvataggio…' : 'Salva profilo pubblico'),
            ),
          ],
          if (_message case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_reloadRequired)
            OutlinedButton(
              onPressed: _fetch,
              child: const Text('Ricarica profilo'),
            ),
        ],
      ),
    );
  }
}
