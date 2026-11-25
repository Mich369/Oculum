import 'dart:js_interop';

@JS('window.open')
external JSObject? _open(JSString url, JSString target, JSString features);

void openOculumRlDownload(String url) =>
    _open(url.toJS, '_blank'.toJS, 'noopener,noreferrer'.toJS);
