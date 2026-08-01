/// Reads config injected into the page at container-start time (see
/// frontend/env-config-entrypoint.sh + frontend/web/env-config.js), taking priority over the
/// --dart-define build-time value. This exists because Render (and likely other Docker-based
/// hosts) don't reliably pass dashboard Environment Variables through as Docker build args, so
/// baking config in at `flutter build web` time produced empty strings in production even
/// though the variables were set correctly. Reading them at container *runtime* instead sidesteps
/// that platform-specific behaviour entirely — this only depends on standard `docker run -e`,
/// which every container host supports.
///
/// Returns null (falls back to the build-time value) on non-web platforms, or when nothing was
/// actually injected (local `flutter run`/`flutter build web` without the entrypoint script).
library;

export 'runtime_config_stub.dart' if (dart.library.html) 'runtime_config_web.dart';
