import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Reads a global JS variable set by frontend/web/env-config.js (a placeholder locally,
/// overwritten with real values at container startup in production — see runtime_config.dart).
String? readRuntimeConfig(String key) {
  final value = globalContext.getProperty<JSAny?>(key.toJS);
  if (value case JSString s) {
    final str = s.toDart;
    if (str.isNotEmpty) return str;
  }
  return null;
}
