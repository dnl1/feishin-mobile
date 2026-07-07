import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../player/mini_player.dart';

/// Bottom-tab scaffold around the stateful shell branches. Phase 3 extends
/// this with the Busca/Configurações tabs and the mini player docked above
/// the bar (see PLAN.md, phase 3).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Biblioteca',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
