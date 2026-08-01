// Placeholder — overwritten at container startup (see frontend/env-config-entrypoint.sh) with
// real values from the runtime environment. Local `flutter run`/`flutter build web` uses this
// placeholder as-is; empty strings here are treated as "not set" by runtime_config_web.dart,
// which falls back to --dart-define build-time values instead.
window.API_BASE_URL = "";
window.SUPABASE_URL = "";
window.SUPABASE_ANON_KEY = "";
