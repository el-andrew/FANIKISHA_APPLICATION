import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/goals/presentation/goal_detail_screen.dart';
import '../../features/goals/presentation/goal_form_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/verify_phone_screen.dart';
import '../../features/savings/presentation/deposit_screen.dart';
import '../../features/savings/presentation/history_screen.dart';
import 'home_shell.dart';

const _publicRoutes = {'/welcome', '/login', '/register'};

/// Where a user in [auth] may be, given they asked for [location].
@visibleForTesting
String? redirectFor(AuthState auth, String location) => switch (auth) {
  AuthLoading() ||
  AuthRestoreFailed() => location == '/splash' ? null : '/splash',
  SignedOut() => _publicRoutes.contains(location) ? null : '/welcome',
  SignedIn() =>
    _publicRoutes.contains(location) || location == '/splash' ? '/' : null,
};

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  // Re-route only when the user signs in or out. Reacting to profile changes
  // (same state type, new user) would refresh the router mid-navigation and
  // put back a screen that was just closed.
  ref.listen(
    authControllerProvider.select((state) => state.runtimeType),
    (_, _) => auth.value = ref.read(authControllerProvider),
  );

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) =>
        redirectFor(auth.value, state.matchedLocation),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen pages, shown above the tabs.
      GoRoute(path: '/save', builder: (_, _) => const DepositScreen()),
      GoRoute(path: '/goals/new', builder: (_, _) => const GoalFormScreen()),
      GoRoute(
        path: '/goals/:id',
        builder: (_, state) =>
            GoalDetailScreen(goalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/goals/:id/edit',
        builder: (_, state) =>
            GoalFormScreen(goalId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/verify-phone',
        builder: (_, _) => const VerifyPhoneScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    auth.dispose();
  });
  return router;
});
