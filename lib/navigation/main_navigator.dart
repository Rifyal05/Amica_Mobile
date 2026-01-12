import 'package:amica/provider/navigation_provider.dart';
import 'package:amica/provider/post_provider.dart';
import 'package:amica/provider/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mainpage/connect.dart';
import '../mainpage/educative.dart';
import '../mainpage/talk.dart';
import '../mainpage/user_profile_page.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  static const List<Widget> _pages = [
    Connect(),
    Educative(),
    Talk(),
    UserProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchInbox();
    });
  }

  void _handleRefresh(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.read<PostProvider>().refreshPosts();
        break;
      case 2:
        context.read<ChatProvider>().fetchInbox();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: navProvider.selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navProvider.selectedIndex,
        onTap: (index) {
          context.read<NavigationProvider>().setIndex(index);
          _handleRefresh(context, index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Komunitas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Panduan',
          ),

          BottomNavigationBarItem(
            icon: Consumer<ChatProvider>(
              builder: (context, chatProv, child) {
                return Badge(
                  isLabelVisible: chatProv.unreadMessageCount > 0,
                  label: Text('${chatProv.unreadMessageCount}'),
                  backgroundColor: colorScheme.error,
                  child: const Icon(Icons.support_agent_outlined),
                );
              },
            ),
            activeIcon: Consumer<ChatProvider>(
              builder: (context, chatProv, child) {
                return Badge(
                  isLabelVisible: chatProv.unreadMessageCount > 0,
                  label: Text('${chatProv.unreadMessageCount}'),
                  backgroundColor: colorScheme.error,
                  child: const Icon(Icons.support_agent),
                );
              },
            ),
            label: 'Komunikasi',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
