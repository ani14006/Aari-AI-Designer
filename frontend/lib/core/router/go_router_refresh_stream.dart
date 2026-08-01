import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a broadcast [Stream] into a [Listenable] so GoRouter can react to it via
/// `refreshListenable` — used here to re-evaluate the auth redirect whenever the
/// Supabase auth state changes (sign in, sign up, sign out, token refresh).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
