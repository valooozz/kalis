import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalis/screens/records/records_screen.dart';
import 'package:kalis/screens/settings/settings_screen.dart';
import 'package:kalis/screens/onboarding/onboarding_screen.dart';
import 'package:kalis/screens/figures/archived_figures_screen.dart';
import '../../providers/core_providers.dart';
import '../../screens/today/today_screen.dart';
import '../../screens/figures/figures_screen.dart';
import '../../screens/places/places_screen.dart';
import '../../screens/planning/planning_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/renfos/renfos_screen.dart';

// Provider du router
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingSeen = ref.watch(onboardingSeenProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      // Tant que l'auth ou la préférence d'accueil est en cours de chargement,
      // on ne redirige pas.
      if (authState.isLoading || onboardingSeen.isLoading) return null;

      final seen = onboardingSeen.valueOrNull ?? false;
      final isOnboarding = state.uri.path == '/onboarding';

      if (!seen && !isOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/figures',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FiguresScreen()),
          ),
          GoRoute(
            path: '/places',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlacesScreen()),
          ),
          GoRoute(
            path: '/renfos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RenfosScreen()),
          ),
          GoRoute(
            path: '/today',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodayScreen()),
          ),
          GoRoute(
            path: '/planning',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlanningScreen()),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/archived-figures',
            builder: (context, state) => const ArchivedFiguresScreen(),
          ),
          GoRoute(
            path: '/records',
            builder: (context, state) => const RecordsScreen(),
          ),
        ],
      ),
    ],
  );
});
