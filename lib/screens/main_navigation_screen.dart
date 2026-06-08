import 'package:flutter/material.dart';
import 'stock_in/stock_in_list_screen.dart';
import 'stock_out/stock_out_list_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Colors matching MSIC_FE
  static const _indigo600 = Color(0xFF4F46E5);
  static const _gray500 = Color(0xFF6B7280);

  final List<Widget> _screens = const [
    StockInListScreen(),
    StockOutListScreen(),
    SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.move_to_inbox_outlined),
      activeIcon: Icon(Icons.move_to_inbox),
      label: 'Stock-In',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.outbox_outlined),
      activeIcon: Icon(Icons.outbox),
      label: 'Stock-Out',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _indigo600,
        unselectedItemColor: _gray500,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
