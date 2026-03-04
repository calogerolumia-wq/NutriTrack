import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../importer/import_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    ImportScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Settimana'),
          NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Importa'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), label: 'Impostazioni'),
        ],
      ),
    );
  }
}
