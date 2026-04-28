import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kalis/l10n/app_localizations.dart';

class MainScreen extends StatelessWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  int? _locationToIndex(String location) {
    if (location.startsWith('/figures')) return 0;
    if (location.startsWith('/today')) return 1;
    if (location.startsWith('/planning')) return 2;
    return null;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/figures');
      case 1:
        context.go('/today');
      case 2:
        context.go('/planning');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: currentIndex == null
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => _onItemTapped(context, index),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.self_improvement),
                  label: lbl.tabFigures,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.today),
                  label: lbl.tabToday,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: lbl.tabPlanning,
                ),
              ],
            ),
    );
  }
}
