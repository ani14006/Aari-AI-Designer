import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConstants.supabaseUrl.isEmpty ||
      AppConstants.supabaseAnonKey.isEmpty) {
    // Let the UI still boot for local preview; auth-dependent screens simply won't work
    // until real --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY values are supplied.
    debugPrint(
        'Supabase not configured (SUPABASE_URL / SUPABASE_ANON_KEY missing) — auth disabled.');
  } else {
    await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey);
  }

  runApp(const ProviderScope(child: AariApp()));
}
