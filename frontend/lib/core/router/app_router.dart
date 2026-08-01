import 'package:go_router/go_router.dart';

import '../../models/design_model.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/design/design_screen.dart';
import '../../screens/design/order_details_screen.dart';
import '../../screens/design/palette_selection_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/home/main_shell.dart';
import '../../screens/landing/landing_screen.dart';
import '../../screens/result/result_screen.dart';
import '../../screens/settings/cart_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../services/auth_service.dart';
import 'go_router_refresh_stream.dart';

// Routes that are fine to stay on when signed out. Notably excludes '/splash': that screen is
// only ever a momentary placeholder and must always redirect somewhere, never stay visible.
const _signedOutRoutes = {'/welcome', '/login', '/signup', '/forgot-password'};

/// Single source of truth for auth-based navigation: redirects unauthenticated users away
/// from protected routes, and authenticated users away from splash/welcome/login/signup.
/// Re-evaluated automatically on every Supabase auth event via [refreshListenable] — this is
/// what makes a successful sign-in/sign-up actually navigate the user, instead of leaving them
/// stranded.
String? _authRedirect(_, GoRouterState state) {
  final isLoggedIn = AuthService.instance.currentUser != null;
  final location = state.matchedLocation;

  if (location == '/splash') return isLoggedIn ? '/home' : '/welcome';
  if (!isLoggedIn && !_signedOutRoutes.contains(location)) return '/welcome';
  if (isLoggedIn && _signedOutRoutes.contains(location)) return '/home';
  return null;
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: _authRedirect,
  refreshListenable:
      GoRouterRefreshStream(AuthService.instance.authStateChanges),
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
        path: '/welcome', builder: (context, state) => const LandingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(path: '/home', builder: (context, state) => const MainShell()),
    GoRoute(path: '/design', builder: (context, state) => const DesignScreen()),
    GoRoute(
        path: '/order-details',
        builder: (context, state) => const OrderDetailsScreen()),
    GoRoute(
        path: '/palette-selection',
        builder: (context, state) => const PaletteSelectionScreen()),
    GoRoute(
      path: '/result',
      builder: (context, state) =>
          ResultScreen(design: state.extra as DesignModel),
    ),
    GoRoute(
        path: '/history', builder: (context, state) => const HistoryScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
  ],
);
