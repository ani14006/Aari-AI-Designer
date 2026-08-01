import 'package:flutter/material.dart';

import '../../widgets/common/luxury_bottom_nav.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

/// Bottom-navigation shell hosting the three persistent tabs: Home, History, Settings.
/// Design / Result are pushed full-screen on top of this shell rather than living in it.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [HomeScreen(), HistoryScreen(), SettingsScreen()];

  static const _navItems = [
    LuxuryNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home'),
    LuxuryNavItem(
        icon: Icons.history_rounded,
        activeIcon: Icons.history_rounded,
        label: 'History'),
    LuxuryNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: LuxuryBottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: _navItems,
      ),
    );
  }
}
