typedef OculumBindSupabaseAuth = Future<void> Function();

/// Keeps the SDK startup in flight even when a screen stops waiting for it.
class OculumSupabaseStartup {
  Future<bool>? _pending;
  OculumBindSupabaseAuth? _bindAuth;
  bool _sdkNeedsCleanup = false;
  bool _ready = false;

  Future<bool> waitUntilReady({
    required Future<OculumBindSupabaseAuth> Function() startSdk,
    required Future<void> Function() disposeIncompleteSdk,
    required Duration timeout,
    void Function()? onWaitExpired,
    void Function(Object error)? onError,
  }) {
    if (_ready) return Future<bool>.value(true);
    final pending = _pending ??= _start(
      startSdk,
      disposeIncompleteSdk,
      onError,
    ).whenComplete(() => _pending = null);
    return pending.timeout(
      timeout,
      onTimeout: () {
        onWaitExpired?.call();
        return false;
      },
    );
  }

  Future<bool> _start(
    Future<OculumBindSupabaseAuth> Function() startSdk,
    Future<void> Function() disposeIncompleteSdk,
    void Function(Object error)? onError,
  ) async {
    try {
      if (_sdkNeedsCleanup) {
        await disposeIncompleteSdk();
        _sdkNeedsCleanup = false;
      }
      if (_bindAuth == null) {
        // Only a later attempt may clean up a failed SDK. A UI timeout never
        // changes the lifetime of the native storage or network operation.
        _sdkNeedsCleanup = true;
        _bindAuth = await startSdk();
        _sdkNeedsCleanup = false;
      }
      await _bindAuth!();
      _ready = true;
      return true;
    } catch (error) {
      onError?.call(error);
      return false;
    }
  }
}
