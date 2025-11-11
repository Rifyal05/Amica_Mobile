import 'package:amica/provider/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:amica/mainpage/profile.dart';
import 'package:provider/provider.dart';
import '../mainpage/connect.dart';
import '../mainpage/educative.dart';
import '../mainpage/talk.dart';

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  static const List<Widget> _pages = [
    Connect(),
    Educative(),
    Talk(),
    ProfilePage(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Komunitas'),
    BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Panduan'),
    BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), activeIcon: Icon(Icons.support_agent), label: 'Komunikasi'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NavigationProvider>();

    return Scaffold(
      body: IndexedStack(
        index: provider.selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: provider.selectedIndex,
        onTap: (index) => context.read<NavigationProvider>().setIndex(index),
        items: _navItems,
      ),
    );
  }
}