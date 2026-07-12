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
