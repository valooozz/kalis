import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatelessWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/figures')) return 0;
    if (location.startsWith('/today')) return 1;
    if (location.startsWith('/planning')) return 2;
    return 1;
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
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Figures',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: "Aujourd'hui",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Planification',
          ),
        ],
      ),
    );
  }
}