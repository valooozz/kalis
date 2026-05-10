import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kalis/l10n/app_localizations.dart';

import 'package:kalis/screens/figures/figures_screen.dart';
import 'package:kalis/screens/planning/planning_screen.dart';
import 'package:kalis/screens/today/today_screen.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;

  final List<String> _routes = ['/figures', '/today', '/planning'];

  int _locationToIndex(String location) {
    if (location.startsWith('/figures')) return 0;
    if (location.startsWith('/today')) return 1;
    if (location.startsWith('/planning')) return 2;
    return 1; // fallback = Today
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageWithRoute(int index) {
    if (_pageController.hasClients && _pageController.page?.round() != index) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    // Synchronisation route -> PageView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPageWithRoute(currentIndex);
    });

    // Si route hors tabs → écran plein
    final isTabRoute = _routes.any((r) => location.startsWith(r));
    if (!isTabRoute) {
      return Scaffold(body: widget.child);
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (index != currentIndex) {
            context.go(_routes[index]);
          }
        },
        children: const [FiguresScreen(), TodayScreen(), PlanningScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) {
            context.go(_routes[index]);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: lbl.tabFigures,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: lbl.tabToday),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: lbl.tabPlanning,
          ),
        ],
      ),
    );
  }
}
