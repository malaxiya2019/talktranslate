import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// 应用主壳 — 底部三 Tab 导航
///
/// Tab 0: 📞 通话 (HomeScreen 联系人页)
/// Tab 1: 🕐 历史 (HistoryScreen)
/// Tab 2: ⚙️ 设置 (SettingsScreen)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.phone_outlined),
            selectedIcon: Icon(Icons.phone),
            label: '通话',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
