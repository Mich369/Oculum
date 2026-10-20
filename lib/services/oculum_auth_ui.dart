import 'package:flutter/material.dart';
import 'package:oculum/services/oculum_auth_service.dart';

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
    setState(() => _busy = true);
    final success = await operation();
    if (!mounted) return;
    setState(() => _busy = false);
    if (success && OculumAuthService.instance.pendingEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Controlla la tua email. Usa il codice ricevuto o il link di conferma.',
          ),
        ),
      );
    } else if (success && successMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
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
              onChanged: _busy
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
                            'Se l’account esiste, riceverai un link per reimpostare la password.',
                      ),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Password dimenticata?'),
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
