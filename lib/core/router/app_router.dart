import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalis/screens/settings/settings_screen.dart';
import '../../providers/core_providers.dart';
import '../../screens/today/today_screen.dart';
import '../../screens/figures/figures_screen.dart';
import '../../screens/planning/planning_screen.dart';
import '../../screens/main/main_screen.dart';

// Provider du router
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      // Tant que l'auth est en cours de chargement, on ne redirige pas
      if (authState.isLoading) return null;
      // Si l'utilisateur n'est pas connecté, on ne redirige pas
      // (la connexion anonyme se fait dans main.dart)
      return null;
    },
    routes: [
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
        ],
      ),
    ],
  );
});
