/// Saves image bytes to the platform's natural "downloads" location: the native photo
/// gallery on mobile/desktop (via `gal`), or a browser file download on web (`gal` has no web
/// implementation, so calling it there throws MissingPluginException). `name` should not
/// include a file extension.
library;

export 'gallery_download_io.dart' if (dart.library.html) 'gallery_download_web.dart';
