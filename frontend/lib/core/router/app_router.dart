import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/biometric_unlock_screen.dart';
import '../../presentation/screens/vault_dashboard_screen.dart';
import '../../presentation/screens/add_password_screen.dart';
import '../../presentation/screens/edit_password_screen.dart';
import '../../presentation/screens/view_password_screen.dart';
import '../../presentation/screens/settings_screen.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const biometric = '/biometric';
  static const vault = '/vault';
  static const addPassword = '/vault/add';
  static const viewPassword = '/vault/:id';
  static const editPassword = '/vault/:id/edit';
  static const settings = '/settings';

  static String viewPasswordPath(String id) => '/vault/$id';
  static String editPasswordPath(String id) => '/vault/$id/edit';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Use read — the router must NOT rebuild on every auth change.
  // GoRouterRefreshStream triggers re-evaluation of the redirect callback,
  // which reads fresh state directly from the notifier each time.
  final authNotifier = ref.read(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(authNotifier),
    redirect: (BuildContext context, GoRouterState state) {
      // Always read fresh state here — not from a captured closure variable
      final authState = authNotifier.state;
      final location = state.matchedLocation;

      // Wait for auth state to be determined
      if (authState.status == AuthStatus.loading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isVaultUnlocked = authState.isVaultUnlocked;
      final onboardingDone = authState.onboardingDone;

      // Show onboarding first time
      if (!onboardingDone && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      // Not logged in — redirect to login
      if (!isAuthenticated &&
          !_isPublicRoute(location) &&
          location != AppRoutes.splash) {
        return AppRoutes.login;
      }

      // Logged in but vault locked — require biometric/pin
      if (isAuthenticated && !isVaultUnlocked && _isProtectedRoute(location)) {
        return AppRoutes.biometric;
      }

      // Already authenticated — redirect away from auth screens
      if (isAuthenticated &&
          isVaultUnlocked &&
          _isAuthRoute(location)) {
        return AppRoutes.vault;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.biometric,
        builder: (_, __) => const BiometricUnlockScreen(),
      ),
      GoRoute(
        path: AppRoutes.vault,
        builder: (_, __) => const VaultDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.addPassword,
        builder: (_, __) => const AddPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.viewPassword,
        builder: (_, state) => ViewPasswordScreen(
          entryId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.editPassword,
        builder: (_, state) => EditPasswordScreen(
          entryId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri}'),
      ),
    ),
  );
});

bool _isPublicRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.onboarding ||
    location == AppRoutes.splash;

bool _isAuthRoute(String location) =>
    location == AppRoutes.login || location == AppRoutes.register;

bool _isProtectedRoute(String location) =>
    location.startsWith('/vault') || location == AppRoutes.settings;

// Bridges a Listenable to GoRouter's refresh mechanism
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Listenable listenable) {
    listenable.addListener(notifyListeners);
  }
}
