import '../config/runtime_config.dart';

/// App-wide constants: API config, spacing scale, look styles.
class AppConstants {
  AppConstants._();

  /// Base URL for the FastAPI backend. Override at build time with:
  /// flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
  ///
  /// In production (the Docker/nginx build), a runtime-injected value (see
  /// core/config/runtime_config.dart) takes priority over this build-time default — Render
  /// (and likely other Docker hosts) don't reliably pass dashboard env vars through as Docker
  /// build args, so relying on --dart-define alone left this baked in as empty in production.
  static const String _apiBaseUrlBuildTime = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  static String get apiBaseUrl =>
      readRuntimeConfig('API_BASE_URL') ?? _apiBaseUrlBuildTime;

  /// Supabase project URL + anon (public) key. Found in the Supabase dashboard under Project
  /// Settings -> API. Same runtime-injection priority as apiBaseUrl above.
  static const String _supabaseUrlBuildTime =
      String.fromEnvironment('SUPABASE_URL');
  static String get supabaseUrl =>
      readRuntimeConfig('SUPABASE_URL') ?? _supabaseUrlBuildTime;

  static const String _supabaseAnonKeyBuildTime =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static String get supabaseAnonKey =>
      readRuntimeConfig('SUPABASE_ANON_KEY') ?? _supabaseAnonKeyBuildTime;

  /// External storefront the "Buy Materials" button on the Result screen opens.
  static const String materialsShopUrl =
      'https://shop.aariembroideryartisthub.com/';

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  /// Vertical padding for full-bleed marketing sections (Landing screen) — Apple-style generous
  /// section rhythm; no other screen needs a token this large.
  static const double spaceSection = 96;
}

/// The six regenerate "look" presets from the Result screen.
class LookStyles {
  LookStyles._();

  static const String luxury = 'Luxury Look';
  static const String traditional = 'Traditional Look';
  static const String minimal = 'Minimal Look';
  static const String bridal = 'Bridal Look';
  static const String templeJewellery = 'Temple Jewellery Style';
  static const String modernDesigner = 'Modern Designer Look';

  static const List<String> all = [
    luxury,
    traditional,
    minimal,
    bridal,
    templeJewellery,
    modernDesigner,
  ];
}

/// Shared responsive breakpoints (standard Material-ish widths) used to switch between
/// mobile/tablet/desktop layouts, e.g. on the Home screen.
class Breakpoints {
  Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wideDesktop = 1280;

  /// Dashboard-style screens (Home, History) with grids.
  static const double maxContentWidth = 1300;

  /// Narrow auth forms (Login/Signup/Forgot Password) — a login card shouldn't stretch wide.
  static const double authMaxWidth = 480;

  /// Single-column form/list screens (Design upload, Order Details, Settings, Cart).
  static const double formMaxWidth = 640;

  /// Result screen — a bit wider so the preview image has room to breathe.
  static const double resultMaxWidth = 760;

  /// Palette-selection screen when laid out as 3 side-by-side cards on wide screens.
  static const double paletteMaxWidth = 1100;
}

class BeadPalette {
  BeadPalette._();

  static const List<String> names = [
    'Antique Gold',
    'Pearl White',
    'Ruby Red',
    'Emerald Green',
    'Crystal',
    'Copper',
    'Silver',
    'Black',
    'Rose Gold',
  ];
}

/// Order-details step options — must stay in sync with the backend enums in
/// backend/app/schemas/design.py (Occasion, BlouseSilhouette, EmbroideryCoverage).
class Occasions {
  Occasions._();

  static const List<String> all = [
    'Wedding',
    'Reception',
    'Engagement',
    'Festival',
    'Party',
    'Casual',
  ];
}

class BlouseSilhouettes {
  BlouseSilhouettes._();

  static const List<String> all = [
    'Princess Cut',
    'Sweetheart Neck',
    'Boat Neck',
    'Halter Neck',
    'Off-Shoulder',
    'Traditional Round Neck',
    'High Neck',
    'Deep-V Neck',
    'Backless',
  ];
}

class EmbroideryCoverages {
  EmbroideryCoverages._();

  static const light = 'Light';
  static const medium = 'Medium';
  static const heavy = 'Heavy';
  static const fullBridal = 'Full Bridal';

  static const List<String> all = [light, medium, heavy, fullBridal];
}
