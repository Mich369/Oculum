import 'package:flutter/material.dart';
import 'package:oculum/services/oculum_account_profile.dart';
import 'package:oculum/services/oculum_auth_service.dart';

class OculumPasswordRecoveryHost extends StatefulWidget {
  const OculumPasswordRecoveryHost({
    super.key,
    required this.auth,
    required this.navigatorKey,
    required this.child,
  });

  final OculumAuthService auth;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<OculumPasswordRecoveryHost> createState() =>
      _OculumPasswordRecoveryHostState();
}

class _OculumPasswordRecoveryHostState
    extends State<OculumPasswordRecoveryHost> {
  DialogRoute<bool>? _route;
  String? _accountId;
  int _lastInvalidLink = 0;

  @override
  void initState() {
    super.initState();
    widget.auth.passwordRecovery.addListener(_scheduleRecovery);
    widget.auth.invalidAuthLink.addListener(_scheduleRecovery);
    _scheduleRecovery();
  }

  void _scheduleRecovery() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showRecovery();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _showRecovery() {
    final invalidLink = widget.auth.invalidAuthLink.value;
    if (invalidLink != _lastInvalidLink) {
      _lastInvalidLink = invalidLink;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text(OculumAuthService.invalidAuthLinkMessage)),
      );
    }
    final accountId = widget.auth.passwordRecovery.value;
    if (_accountId == accountId) return;
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    final previous = _route;
    if (previous != null && previous.isActive) navigator.removeRoute(previous);
    _route = null;
    _accountId = accountId;
    if (accountId == null) return;
    final route = DialogRoute<bool>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => _OculumPasswordRecoveryDialog(
        auth: widget.auth,
        accountId: accountId,
      ),
    );
    _route = route;
    navigator.push(route).then((updated) {
      if (!mounted) return;
      if (_route == route) {
        _route = null;
        _accountId = null;
        widget.auth.dismissPasswordRecovery();
      }
      if (updated == true) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('Password aggiornata.')));
      }
    });
  }

  @override
  void dispose() {
    widget.auth.passwordRecovery.removeListener(_scheduleRecovery);
    widget.auth.invalidAuthLink.removeListener(_scheduleRecovery);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _OculumPasswordRecoveryDialog extends StatefulWidget {
  const _OculumPasswordRecoveryDialog({
    required this.auth,
    required this.accountId,
  });

  final OculumAuthService auth;
  final String accountId;

  @override
  State<_OculumPasswordRecoveryDialog> createState() =>
      _OculumPasswordRecoveryDialogState();
}

class _OculumPasswordRecoveryDialogState
    extends State<_OculumPasswordRecoveryDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_busy) return;
    if (_password.text != _confirmation.text) {
      setState(() => _error = 'Le password devono coincidere.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final updated = await widget.auth.completePasswordRecovery(
      widget.accountId,
      _password.text,
    );
    if (!mounted) return;
    if (updated) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error =
          widget.auth.state.errorMessage ??
          'Impossibile aggiornare la password. Riprova.';
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      title: const Text('Reimposta password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nuova password',
              helperText: 'Almeno 8 caratteri',
            ),
          ),
          TextField(
            controller: _confirmation,
            enabled: !_busy,
            obscureText: true,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(labelText: 'Conferma password'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Aggiorna password'),
        ),
      ],
    ),
  );
}

class OculumAuthPanel extends StatelessWidget {
  const OculumAuthPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = OculumAuthService.instance;
    return ValueListenableBuilder<OculumAuthState>(
      valueListenable: auth.stateNotifier,
      builder: (context, state, _) {
        return Card(
          color: Colors.black.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.displayLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  state.message ??
                      (state.isAuthenticated
                          ? 'Sessione ${state.providerLabel} attiva.'
                          : 'Continua in locale oppure accedi per le funzioni online.'),
                ),
                if (state.isOffline || state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        state.isOffline ? Icons.cloud_off : Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(state.errorMessage ?? 'Offline')),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                const _OculumEmailAccessForm(),
                const SizedBox(height: 10),
                if (!state.isAuthenticated) ...[
                  _ProviderButton(
                    label: 'Google',
                    icon: Icons.g_mobiledata,
                    availability: auth.providerAvailabilityLabel(
                      OculumAuthProvider.google,
                    ),
                    enabled:
                        !state.isLoading &&
                        auth.isProviderSupported(OculumAuthProvider.google) &&
                        auth.isSupabaseReady,
                    onPressed: auth.signInWithGoogle,
                  ),
                  const SizedBox(height: 8),
                  _ProviderButton(
                    label: 'Apple',
                    icon: Icons.apple,
                    availability: auth.providerAvailabilityLabel(
                      OculumAuthProvider.apple,
                    ),
                    enabled:
                        !state.isLoading &&
                        auth.isProviderSupported(OculumAuthProvider.apple) &&
                        auth.isSupabaseReady,
                    onPressed: auth.signInWithApple,
                  ),
                  const SizedBox(height: 8),
                ],
                if (state.isAuthenticated &&
                    auth.isProviderSupported(OculumAuthProvider.google)) ...[
                  if (auth.hasGoogleIdentity)
                    const Text('Account Google collegato')
                  else if (auth.canLinkGoogle)
                    OutlinedButton.icon(
                      onPressed: state.isLoading ? null : auth.linkGoogle,
                      icon: const Icon(Icons.link),
                      label: const Text('Collega account Google'),
                    ),
                  const SizedBox(height: 8),
                ],
                if (state.canSyncToCloud && state.userId != null)
                  OculumAccountProfilePanel.supabase(
                    key: ValueKey(state.userId),
                    accountId: state.userId!,
                    canClaimPublicCode: auth.hasVerifiedEmail,
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!state.isAuthenticated)
                      OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : auth.continueAsGuest,
                        icon: const Icon(Icons.device_unknown),
                        label: const Text('Continua senza account'),
                      ),
                    if (state.isLoading)
                      TextButton.icon(
                        onPressed: auth.cancelPendingSignIn,
                        icon: const Icon(Icons.close),
                        label: const Text('Annulla'),
                      ),
                    if (!state.isLoading && state.errorMessage != null)
                      TextButton.icon(
                        onPressed: auth.retryLastSignIn,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    if (state.isAuthenticated)
                      OutlinedButton.icon(
                        onPressed: state.isLoading ? null : auth.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Esci'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OculumEmailAccessForm extends StatefulWidget {
  const _OculumEmailAccessForm();
  @override
  State<_OculumEmailAccessForm> createState() => _OculumEmailAccessFormState();
}

class _OculumEmailAccessFormState extends State<_OculumEmailAccessForm> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<bool> Function() operation, {
    String? successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final success = await operation();
    if (!mounted) return;
    setState(() => _busy = false);
    if (success && successMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } else if (success && OculumAuthService.instance.pendingEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Controlla la tua email. Usa il codice ricevuto o il link di conferma.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = OculumAuthService.instance;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final state = auth.state;
        final hasAccount = state.isAuthenticated && !state.isGuest;
        final protectedGuest = state.isAuthenticated && state.isGuest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mantieni l’accesso su questo dispositivo'),
              value: auth.rememberAccess,
              onChanged: _busy || state.isLoading
                  ? null
                  : (value) => auth.setRememberAccess(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (!state.isAuthenticated)
              OutlinedButton.icon(
                onPressed: _busy || !auth.isSupabaseReady
                    ? null
                    : () => _run(auth.signInAsProtectedGuest),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Ospite online protetto'),
              ),
            if (!hasAccount) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                enabled: !_busy && auth.isSupabaseReady,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Account Oculum',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              enabled: !_busy && auth.isSupabaseReady,
              obscureText: _hidePassword,
              autofillHints: hasAccount
                  ? const [AutofillHints.newPassword]
                  : const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: hasAccount ? 'Nuova password' : 'Password',
                helperText: hasAccount
                    ? 'La password viene gestita da Supabase e non salvata nella scheda.'
                    : 'Almeno 8 caratteri. Non viene salvata in Oculum.',
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  tooltip: _hidePassword
                      ? 'Mostra password'
                      : 'Nascondi password',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (hasAccount)
              OutlinedButton.icon(
                onPressed: _busy || !auth.isSupabaseReady
                    ? null
                    : () => _run(
                        () => auth.setAccountPassword(_password.text),
                        successMessage: 'Password aggiornata sul tuo account.',
                      ),
                icon: const Icon(Icons.password_outlined),
                label: const Text('Imposta password'),
              )
            else if (protectedGuest)
              OutlinedButton.icon(
                onPressed: _busy || !auth.isSupabaseReady
                    ? null
                    : () => _run(
                        () => auth.linkGuestEmailPassword(
                          _email.text,
                          _password.text,
                        ),
                      ),
                icon: const Icon(Icons.link),
                label: const Text('Collega email e password'),
              )
            else
              OutlinedButton.icon(
                onPressed: _busy || !auth.isSupabaseReady
                    ? null
                    : () => _run(
                        () => auth.signInWithEmailPassword(
                          _email.text,
                          _password.text,
                        ),
                      ),
                icon: const Icon(Icons.login),
                label: const Text('Accedi con email e password'),
              ),
            if (!hasAccount) ...[
              TextButton.icon(
                onPressed: _busy || !auth.isSupabaseReady
                    ? null
                    : () => _run(
                        () => auth.requestPasswordReset(_email.text),
                        successMessage:
                            'Se l’account esiste, riceverai un link. Apri l’ultimo link ricevuto nello stesso browser o nella stessa app.',
                      ),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Hai dimenticato la password?'),
              ),
              TextButton.icon(
                onPressed: _busy || !auth.isSupabaseReady
                    ? null
                    : () => _run(() => auth.requestEmailAccess(_email.text)),
                icon: const Icon(Icons.mail_outline),
                label: Text(
                  protectedGuest
                      ? 'Collega solo email con codice'
                      : 'Ricevi un codice via email',
                ),
              ),
            ],
            if (auth.pendingEmail != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _code,
                enabled: !_busy,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(
                  labelText: 'Codice ricevuto via email',
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => auth.verifyEmailAccess(_code.text)),
                child: const Text('Conferma codice'),
              ),
            ],
            if (_busy) const LinearProgressIndicator(),
          ],
        );
      },
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.availability,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final String availability;
  final bool enabled;
  final Future<bool> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Row(
          children: [
            Expanded(child: Text('Accedi con $label')),
            Text(availability, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
